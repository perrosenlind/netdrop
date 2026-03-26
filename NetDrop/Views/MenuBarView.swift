import SwiftUI

struct MenuBarView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TransferManager.self) private var transferManager

    @State private var selectedFavoriteID: UUID?
    @State private var droppedFiles: [String] = []
    @State private var isDragOver = false

    var body: some View {
        VStack(spacing: 0) {
            // Favorite picker
            HStack {
                Text("Upload to:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $selectedFavoriteID) {
                    Text("Select device…").tag(UUID?.none)
                    ForEach(favoritesStore.favorites) { fav in
                        Text("\(fav.name) (\(fav.host))").tag(UUID?.some(fav.id))
                    }
                }
                .labelsHidden()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            // Drop zone
            VStack(spacing: 8) {
                if droppedFiles.isEmpty {
                    Image(systemName: "arrow.down.doc")
                        .font(.title)
                        .foregroundColor(isDragOver ? .accentColor : .secondary)
                    Text("Drop files here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(droppedFiles.prefix(5), id: \.self) { path in
                        HStack {
                            Image(systemName: "doc")
                                .font(.caption)
                            Text((path as NSString).lastPathComponent)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                    if droppedFiles.count > 5 {
                        Text("+\(droppedFiles.count - 5) more")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 3])
                    )
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                for provider in providers {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { data, _ in
                        guard let data = data as? Data,
                              let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                        DispatchQueue.main.async {
                            if !droppedFiles.contains(url.path) {
                                droppedFiles.append(url.path)
                            }
                        }
                    }
                }
                return true
            }

            // Upload button
            Button {
                uploadFiles()
            } label: {
                Label("Upload \(droppedFiles.count) file(s)", systemImage: "arrow.up.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(droppedFiles.isEmpty || selectedFavoriteID == nil)
            .padding(.horizontal, 12)

            // Active transfer count
            if !transferManager.activeTasks.isEmpty {
                let active = transferManager.activeTasks.filter { $0.status == .inProgress }.count
                if active > 0 {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("\(active) transfer(s) in progress")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 6)
                }
            }

            Divider()
                .padding(.top, 8)

            Button("Open NetDrop") {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first(where: { $0.title.contains("NetDrop") || $0.isKeyWindow }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .buttonStyle(.borderless)
            .padding(.vertical, 6)

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
            .padding(.bottom, 8)
        }
        .frame(width: 280)
    }

    private func uploadFiles() {
        guard let favID = selectedFavoriteID,
              let favorite = favoritesStore.favorites.first(where: { $0.id == favID }) else { return }

        transferManager.uploadMultiple(
            localPaths: droppedFiles,
            remotePath: favorite.remotePath,
            favorite: favorite
        )
        droppedFiles.removeAll()
    }
}
