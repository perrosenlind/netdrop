import SwiftUI

struct SidebarView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Binding var showingAddFavorite: Bool
    @Binding var editingFavorite: Favorite?

    var body: some View {
        @Bindable var store = favoritesStore

        List(selection: $store.selectedFavorite) {
            // Grouped favorites
            ForEach(favoritesStore.groups, id: \.self) { group in
                Section(group) {
                    ForEach(favoritesStore.favorites(inGroup: group)) { favorite in
                        FavoriteRow(favorite: favorite)
                            .tag(favorite)
                            .contextMenu {
                                favoriteContextMenu(favorite)
                            }
                    }
                }
            }

            // Ungrouped favorites
            if !favoritesStore.ungrouped.isEmpty {
                Section(favoritesStore.groups.isEmpty ? "Favorites" : "Ungrouped") {
                    ForEach(favoritesStore.ungrouped) { favorite in
                        FavoriteRow(favorite: favorite)
                            .tag(favorite)
                            .contextMenu {
                                favoriteContextMenu(favorite)
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        .toolbar {
            ToolbarItem {
                Button(action: { showingAddFavorite = true }) {
                    Label("Add Favorite", systemImage: "plus")
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
    }

    @ViewBuilder
    private func favoriteContextMenu(_ favorite: Favorite) -> some View {
        Button("Edit…") {
            editingFavorite = favorite
        }
        Divider()
        Button("Delete", role: .destructive) {
            favoritesStore.delete(favorite)
        }
    }
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
