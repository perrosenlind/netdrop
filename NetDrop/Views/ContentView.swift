import SwiftUI

struct ContentView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TransferManager.self) private var transferManager

    @State private var showingAddFavorite = false
    @State private var showingQuickConnect = false
    @State private var showingMultiDestination = false
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
        .sheet(item: $editingFavorite) { favorite in
            FavoriteEditView(mode: .edit(favorite))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingQuickConnect = true
                } label: {
                    Label("Quick Connect", systemImage: "bolt.fill")
                }
                .help("Connect to a device without saving (Cmd+K)")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingMultiDestination = true
                } label: {
                    Label("Multi-Upload", systemImage: "square.and.arrow.up.on.square")
                }
                .help("Upload files to multiple devices (Cmd+Shift+M)")
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
