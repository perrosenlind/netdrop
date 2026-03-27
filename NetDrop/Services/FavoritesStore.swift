import Foundation

@Observable
class FavoritesStore {
    var favorites: [Favorite] = []
    var selectedFavorite: Favorite?
    /// Empty groups that have no favorites yet
    var emptyGroups: [String] = []

    private let fileURL: URL
    private let groupsFileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("NetDrop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("favorites.json")
        self.groupsFileURL = appDir.appendingPathComponent("groups.json")
        load()
        loadGroups()
    }

    var groups: [String] {
        let favoriteGroups = Set(favorites.map(\.group).filter { !$0.isEmpty })
        let all = favoriteGroups.union(emptyGroups)
        return all.sorted()
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

    // MARK: - Group Management

    func addGroup(_ name: String) {
        guard !name.isEmpty else { return }
        // Only track if no favorites use this group yet
        if !favorites.contains(where: { $0.group == name }) {
            emptyGroups.append(name)
            saveGroups()
        }
    }

    func renameGroup(from oldName: String, to newName: String) {
        // Rename on all favorites in this group
        for i in favorites.indices where favorites[i].group == oldName {
            favorites[i].group = newName
        }
        // Rename in empty groups list
        if let idx = emptyGroups.firstIndex(of: oldName) {
            emptyGroups[idx] = newName
        }
        save()
        saveGroups()
    }

    func deleteGroup(_ name: String) {
        // Move all favorites in this group to ungrouped
        for i in favorites.indices where favorites[i].group == name {
            favorites[i].group = ""
        }
        emptyGroups.removeAll { $0 == name }
        save()
        saveGroups()
    }

    private func loadGroups() {
        guard FileManager.default.fileExists(atPath: groupsFileURL.path) else { return }
        do {
            let data = try Data(contentsOf: groupsFileURL)
            emptyGroups = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Failed to load groups: \(error)")
        }
    }

    private func saveGroups() {
        // Remove groups that have favorites (no longer need to be tracked as empty)
        let usedGroups = Set(favorites.map(\.group).filter { !$0.isEmpty })
        emptyGroups.removeAll { usedGroups.contains($0) }

        do {
            let data = try JSONEncoder().encode(emptyGroups)
            try data.write(to: groupsFileURL, options: .atomic)
        } catch {
            print("Failed to save groups: \(error)")
        }
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
