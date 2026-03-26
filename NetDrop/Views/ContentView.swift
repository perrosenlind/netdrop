import SwiftUI

struct ContentView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TransferManager.self) private var transferManager

    @State private var showingAddFavorite = false
    @State private var showingQuickConnect = false
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
                ContentUnavailableView(
                    "No Connection Selected",
                    systemImage: "network",
                    description: Text("Select a favorite from the sidebar or add a new connection.")
                )
            }
        }
        .sheet(isPresented: $showingAddFavorite) {
            FavoriteEditView(mode: .add)
        }
        .sheet(isPresented: $showingQuickConnect) {
            QuickConnectView()
        }
        .sheet(item: $editingFavorite) { favorite in
            FavoriteEditView(mode: .edit(favorite))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingQuickConnect = true
                } label: {
                    Label("Quick Connect", systemImage: "bolt.horizontal.fill")
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        .frame(minWidth: 700, minHeight: 450)
    }
}
