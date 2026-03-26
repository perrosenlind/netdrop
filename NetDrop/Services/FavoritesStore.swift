import Foundation

@Observable
class FavoritesStore {
    var favorites: [Favorite] = []
    var selectedFavorite: Favorite?

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("NetDrop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("favorites.json")
        load()
    }

    var groups: [String] {
        let allGroups = Set(favorites.map(\.group).filter { !$0.isEmpty })
        return allGroups.sorted()
    }

    var ungrouped: [Favorite] {
        favorites.filter { $0.group.isEmpty }
    }

    func favorites(inGroup group: String) -> [Favorite] {
        favorites.filter { $0.group == group }
    }

    func add(_ favorite: Favorite) {
        favorites.append(favorite)
        save()
    }

    func update(_ favorite: Favorite) {
        if let index = favorites.firstIndex(where: { $0.id == favorite.id }) {
            favorites[index] = favorite
            save()
        }
    }

    func delete(_ favorite: Favorite) {
        favorites.removeAll { $0.id == favorite.id }
        if selectedFavorite?.id == favorite.id {
            selectedFavorite = nil
        }
        save()
    }

    func delete(at offsets: IndexSet) {
        let toDelete = offsets.map { favorites[$0] }
        favorites.remove(atOffsets: offsets)
        if let selected = selectedFavorite, toDelete.contains(where: { $0.id == selected.id }) {
            selectedFavorite = nil
        }
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            favorites = try JSONDecoder().decode([Favorite].self, from: data)
        } catch {
            print("Failed to load favorites: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(favorites)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save favorites: \(error)")
        }
    }
}
