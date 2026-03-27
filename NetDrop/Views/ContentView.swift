import SwiftUI

enum DetailMode {
    case devices
    case backups
}

struct ContentView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TransferManager.self) private var transferManager

    @State private var showingAddFavorite = false
    @State private var showingQuickConnect = false
    @State private var showingMultiDestination = false
    @State private var showingDiffPicker = false
    @State private var editingFavorite: Favorite?
    @State private var detailMode: DetailMode = .devices

    var body: some View {
        @Bindable var store = favoritesStore

        NavigationSplitView {
            SidebarView(
                showingAddFavorite: $showingAddFavorite,
                editingFavorite: $editingFavorite
            )
        } detail: {
            switch detailMode {
            case .devices:
                if let favorite = favoritesStore.selectedFavorite {
                    TransferView(favorite: favorite)
                } else {
                    WelcomeView(
                        showingAddFavorite: $showingAddFavorite,
                        showingQuickConnect: $showingQuickConnect,
                        showingMultiDestination: $showingMultiDestination
                    )
                }
            case .backups:
                BackupMainView()
            }
        }
        .sheet(isPresented: $showingAddFavorite) {
            FavoriteEditView(mode: .add)
        }
        .sheet(isPresented: $showingQuickConnect) {
            QuickConnectView()
        }
        .sheet(isPresented: $showingMultiDestination) {
            MultiDestinationView()
        }
        .sheet(isPresented: $showingDiffPicker) {
            DiffPickerView()
        }
        .sheet(item: $editingFavorite) { favorite in
            FavoriteEditView(mode: .edit(favorite))
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingQuickConnect = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                        Text("Quick Connect")
                    }
                }
                .help("Connect to a device without saving (Cmd+K)")

                Button {
                    showingMultiDestination = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up.on.square")
                        Text("Multi-Upload")
                    }
                }
                .help("Upload files to multiple devices (Cmd+Shift+M)")

                Button {
                    if detailMode == .backups {
                        detailMode = .devices
                    } else {
                        favoritesStore.selectedFavorite = nil
                        detailMode = .backups
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: detailMode == .backups ? "clock.arrow.circlepath.fill" : "clock.arrow.circlepath")
                        Text("Backups")
                    }
                }
                .help("Config backup manager (Cmd+B)")

                Button {
                    showingDiffPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Diff")
                    }
                }
                .help("Compare two config files side by side")
            }
        }
        .onChange(of: favoritesStore.selectedFavorite) { _, newValue in
            if newValue != nil {
                detailMode = .devices
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddFavorite)) { _ in
            showingAddFavorite = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showQuickConnect)) { _ in
            showingQuickConnect = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showMultiDestination)) { _ in
            showingMultiDestination = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBackups)) { _ in
            favoritesStore.selectedFavorite = nil
            detailMode = .backups
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}
