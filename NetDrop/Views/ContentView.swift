import SwiftUI

struct ContentView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TransferManager.self) private var transferManager

    @State private var showingAddFavorite = false
    @State private var showingQuickConnect = false
    @State private var showingMultiDestination = false
    @State private var showingBackupScheduler = false
    @State private var showingDiffPicker = false
    @State private var editingFavorite: Favorite?

    var body: some View {
        @Bindable var store = favoritesStore

        NavigationSplitView {
            SidebarView(
                showingAddFavorite: $showingAddFavorite,
                editingFavorite: $editingFavorite
            )
        } detail: {
            if let favorite = favoritesStore.selectedFavorite {
                TransferView(favorite: favorite)
            } else {
                WelcomeView(
                    showingAddFavorite: $showingAddFavorite,
                    showingQuickConnect: $showingQuickConnect,
                    showingMultiDestination: $showingMultiDestination
                )
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
        .sheet(isPresented: $showingBackupScheduler) {
            BackupSchedulerView()
                .frame(width: 600, height: 500)
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
                    showingBackupScheduler = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Backups")
                    }
                }
                .help("Schedule config backups from devices")

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
        .onReceive(NotificationCenter.default.publisher(for: .showAddFavorite)) { _ in
            showingAddFavorite = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showQuickConnect)) { _ in
            showingQuickConnect = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showMultiDestination)) { _ in
            showingMultiDestination = true
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}
