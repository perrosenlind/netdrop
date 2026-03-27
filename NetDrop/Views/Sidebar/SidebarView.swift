import SwiftUI

struct SidebarView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Binding var showingAddFavorite: Bool
    @Binding var editingFavorite: Favorite?

    @State private var collapsedGroups: Set<String> = []
    @State private var showingNewFolder = false
    @State private var newFolderName = ""
    @State private var renamingGroup: String?
    @State private var renameText = ""
    @State private var backupStatus: (favoriteID: UUID, message: String)?
    @State private var viewingConfig: ConfigViewerItem?
    var body: some View {
        List {
            // Grouped favorites
            ForEach(favoritesStore.groups, id: \.self) { group in
                Section {
                    if !collapsedGroups.contains(group) {
                        ForEach(favoritesStore.favorites(inGroup: group)) { favorite in
                            favoriteItem(favorite)
                        }
                    }
                } header: {
                    folderHeader(group)
                }
            }

            // Ungrouped favorites
            if !favoritesStore.ungrouped.isEmpty {
                Section(favoritesStore.groups.isEmpty ? "Favorites" : "Ungrouped") {
                    ForEach(favoritesStore.ungrouped) { favorite in
                        favoriteItem(favorite)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        .toolbar {
            ToolbarItem {
                Menu {
                    Button {
                        showingAddFavorite = true
                    } label: {
                        Label("New Connection", systemImage: "plus")
                    }
                    Button {
                        newFolderName = ""
                        showingNewFolder = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .overlay {
            if favoritesStore.favorites.isEmpty {
                ContentUnavailableView {
                    Label("No Favorites", systemImage: "star")
                } description: {
                    Text("Add a connection to get started.")
                } actions: {
                    Button("Add Favorite") {
                        showingAddFavorite = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewFolder) {
            FolderNameSheet(title: "New Folder", name: $newFolderName) {
                guard !newFolderName.isEmpty else { return }
                // Create folder by adding a placeholder — or just let user assign favorites to it
                // We create an empty group by adding it to the store
                favoritesStore.addGroup(newFolderName)
            }
        }
        .sheet(item: $renamingGroup) { group in
            FolderNameSheet(title: "Rename Folder", name: $renameText) {
                guard !renameText.isEmpty, renameText != group else { return }
                favoritesStore.renameGroup(from: group, to: renameText)
            }
        }
        .sheet(item: $viewingConfig) { item in
            ConfigViewerView(title: item.title, content: item.content)
        }
    }

    private func favoriteItem(_ favorite: Favorite) -> some View {
        FavoriteRow(favorite: favorite)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .listRowBackground(
                favoritesStore.selectedFavorite?.id == favorite.id
                    ? Color.accentColor.opacity(0.3)
                    : Color.clear
            )
            .simultaneousGesture(
                TapGesture(count: 2).onEnded {
                    favoritesStore.selectedFavorite = favorite
                }
            )
            .contextMenu {
                Button("Connect") {
                    favoritesStore.selectedFavorite = favorite
                }
                Divider()
                favoriteContextMenu(favorite)
            }
    }

    private func folderHeader(_ group: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: collapsedGroups.contains(group) ? "folder.fill" : "folder")
                .foregroundStyle(.secondary)
                .font(.caption)

            Text(group)

            Spacer()

            Text("\(favoritesStore.favorites(inGroup: group).count)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if collapsedGroups.contains(group) {
                    collapsedGroups.remove(group)
                } else {
                    collapsedGroups.insert(group)
                }
            }
        }
        .contextMenu {
            Button("Rename…") {
                renameText = group
                renamingGroup = group
            }
            Divider()
            Button("Delete Folder", role: .destructive) {
                favoritesStore.deleteGroup(group)
            }
        }
    }

    @ViewBuilder
    private func favoriteContextMenu(_ favorite: Favorite) -> some View {
        Button("Edit…") {
            editingFavorite = favorite
        }

        Divider()

        Button("Backup Config…") {
            backupConfig(favorite)
        }

        if let status = backupStatus, status.favoriteID == favorite.id {
            Text(status.message)
        }

        Divider()

        if !favoritesStore.groups.isEmpty {
            Menu("Move to Folder") {
                ForEach(favoritesStore.groups, id: \.self) { group in
                    if group != favorite.group {
                        Button(group) {
                            var updated = favorite
                            updated.group = group
                            favoritesStore.update(updated)
                        }
                    }
                }
                if !favorite.group.isEmpty {
                    Divider()
                    Button("Remove from Folder") {
                        var updated = favorite
                        updated.group = ""
                        favoritesStore.update(updated)
                    }
                }
            }
        }

        Divider()
        Button("Delete", role: .destructive) {
            favoritesStore.delete(favorite)
        }
    }

    private func backupConfig(_ favorite: Favorite) {
        // Use NSSavePanel so user picks where to save
        let panel = NSSavePanel()
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let safeName = favorite.name.replacingOccurrences(of: "/", with: "_")
        panel.nameFieldStringValue = "\(safeName)_\(timestamp).conf"
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.text]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        backupStatus = (favoriteID: favorite.id, message: "Backing up…")

        Task {
            do {
                // Use legacy SCP for FortiGate-style devices (sys_config)
                let result = try await SCPService.download(
                    remotePath: "sys_config",
                    localPath: url.path,
                    favorite: favorite,
                    legacySCP: true
                )

                await MainActor.run {
                    if result.exitCode == 0 {
                        backupStatus = (favoriteID: favorite.id, message: "Backup saved")
                        // Offer to view the config
                        if let content = try? String(contentsOf: url, encoding: .utf8) {
                            viewingConfig = ConfigViewerItem(
                                title: "\(favorite.name) — Config Backup",
                                content: content
                            )
                        }
                    } else {
                        backupStatus = (favoriteID: favorite.id, message: "Failed: \(ConnectionTester.friendlyError(from: result.output, authMethod: favorite.authMethod))")
                    }
                    // Clear status after a few seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if backupStatus?.favoriteID == favorite.id {
                            backupStatus = nil
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    backupStatus = (favoriteID: favorite.id, message: "Error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Identifiable wrapper for renamingGroup sheet
extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct FavoriteRow: View {
    let favorite: Favorite

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(favorite.name)
                .font(.body)
                .fontWeight(.medium)
            Text("\(favorite.username)@\(favorite.host)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Folder Name Sheet

struct FolderNameSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    @Binding var name: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.headline)

                TextField("Folder name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 240)
                    .onSubmit { save() }
            }
            .padding()

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(width: 300)
    }

    private func save() {
        onSave()
        dismiss()
    }
}
