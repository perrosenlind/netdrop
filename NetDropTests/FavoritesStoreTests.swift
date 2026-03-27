import XCTest
@testable import NetDrop

final class FavoritesStoreTests: XCTestCase {

    // MARK: - CRUD

    func testAddFavorite() {
        let store = FavoritesStore()
        let initial = store.favorites.count

        let fav = Favorite(name: "Test", host: "192.168.1.1", username: "admin")
        store.add(fav)

        XCTAssertEqual(store.favorites.count, initial + 1)
        XCTAssertEqual(store.favorites.last?.name, "Test")
        XCTAssertEqual(store.favorites.last?.host, "192.168.1.1")

        // Cleanup
        store.delete(fav)
    }

    func testUpdateFavorite() {
        let store = FavoritesStore()
        var fav = Favorite(name: "Old", host: "1.1.1.1", username: "admin")
        store.add(fav)

        fav.name = "New"
        fav.host = "2.2.2.2"
        store.update(fav)

        let updated = store.favorites.first(where: { $0.id == fav.id })
        XCTAssertEqual(updated?.name, "New")
        XCTAssertEqual(updated?.host, "2.2.2.2")

        store.delete(fav)
    }

    func testDeleteFavorite() {
        let store = FavoritesStore()
        let fav = Favorite(name: "ToDelete", host: "1.1.1.1", username: "admin")
        store.add(fav)

        let countBefore = store.favorites.count
        store.delete(fav)

        XCTAssertEqual(store.favorites.count, countBefore - 1)
        XCTAssertNil(store.favorites.first(where: { $0.id == fav.id }))
    }

    func testDeleteClearsSelection() {
        let store = FavoritesStore()
        let fav = Favorite(name: "Selected", host: "1.1.1.1", username: "admin")
        store.add(fav)
        store.selectedFavorite = fav

        store.delete(fav)

        XCTAssertNil(store.selectedFavorite)
    }

    // MARK: - Groups

    func testGroupsReturnsUniqueGroups() {
        let store = FavoritesStore()
        let fav1 = Favorite(name: "A", host: "1.1.1.1", username: "admin", group: "Lab")
        let fav2 = Favorite(name: "B", host: "2.2.2.2", username: "admin", group: "Prod")
        let fav3 = Favorite(name: "C", host: "3.3.3.3", username: "admin", group: "Lab")
        store.add(fav1)
        store.add(fav2)
        store.add(fav3)

        let groups = store.groups
        XCTAssertTrue(groups.contains("Lab"))
        XCTAssertTrue(groups.contains("Prod"))
        XCTAssertEqual(groups.count, Set(groups).count) // no duplicates

        store.delete(fav1)
        store.delete(fav2)
        store.delete(fav3)
    }

    func testUngroupedReturnsOnlyEmptyGroup() {
        let store = FavoritesStore()
        let grouped = Favorite(name: "G", host: "1.1.1.1", username: "admin", group: "Lab")
        let ungrouped = Favorite(name: "U", host: "2.2.2.2", username: "admin", group: "")
        store.add(grouped)
        store.add(ungrouped)

        let result = store.ungrouped
        XCTAssertTrue(result.contains(where: { $0.id == ungrouped.id }))
        XCTAssertFalse(result.contains(where: { $0.id == grouped.id }))

        store.delete(grouped)
        store.delete(ungrouped)
    }

    func testFavoritesInGroup() {
        let store = FavoritesStore()
        let fav1 = Favorite(name: "A", host: "1.1.1.1", username: "admin", group: "Lab")
        let fav2 = Favorite(name: "B", host: "2.2.2.2", username: "admin", group: "Prod")
        store.add(fav1)
        store.add(fav2)

        let labFavs = store.favorites(inGroup: "Lab")
        XCTAssertTrue(labFavs.contains(where: { $0.id == fav1.id }))
        XCTAssertFalse(labFavs.contains(where: { $0.id == fav2.id }))

        store.delete(fav1)
        store.delete(fav2)
    }

    // MARK: - Group Management

    func testAddEmptyGroup() {
        let store = FavoritesStore()
        store.addGroup("TestFolder")

        XCTAssertTrue(store.groups.contains("TestFolder"))

        // Cleanup
        store.deleteGroup("TestFolder")
    }

    func testRenameGroup() {
        let store = FavoritesStore()
        let fav = Favorite(name: "A", host: "1.1.1.1", username: "admin", group: "OldName")
        store.add(fav)

        store.renameGroup(from: "OldName", to: "NewName")

        XCTAssertTrue(store.groups.contains("NewName"))
        XCTAssertFalse(store.groups.contains("OldName"))
        XCTAssertEqual(store.favorites(inGroup: "NewName").count, 1)

        store.delete(fav)
    }

    func testDeleteGroupMovesFavoritesToUngrouped() {
        let store = FavoritesStore()
        let fav = Favorite(name: "A", host: "1.1.1.1", username: "admin", group: "ToDelete")
        store.add(fav)

        store.deleteGroup("ToDelete")

        XCTAssertFalse(store.groups.contains("ToDelete"))
        let updated = store.favorites.first(where: { $0.id == fav.id })
        XCTAssertEqual(updated?.group, "")

        store.delete(fav)
    }

    func testDuplicateIPsAllowed() {
        let store = FavoritesStore()
        let fav1 = Favorite(name: "Lab-FW", host: "10.0.0.1", username: "admin", group: "Lab")
        let fav2 = Favorite(name: "Prod-FW", host: "10.0.0.1", username: "admin", group: "Prod")
        store.add(fav1)
        store.add(fav2)

        let matching = store.favorites.filter { $0.host == "10.0.0.1" }
        XCTAssertGreaterThanOrEqual(matching.count, 2)
        XCTAssertNotEqual(fav1.id, fav2.id)

        store.delete(fav1)
        store.delete(fav2)
    }
}
