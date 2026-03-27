import XCTest
@testable import NetDrop

final class FavoriteModelTests: XCTestCase {

    // MARK: - Defaults

    func testDefaultValues() {
        let fav = Favorite()
        XCTAssertEqual(fav.port, 22)
        XCTAssertEqual(fav.username, "admin")
        XCTAssertEqual(fav.authMethod, .password)
        XCTAssertEqual(fav.remotePath, "/")
        XCTAssertEqual(fav.group, "")
    }

    // MARK: - Codable round-trip

    func testCodableRoundTripKeyAuth() throws {
        let fav = Favorite(
            name: "FGT-01",
            host: "192.168.1.1",
            port: 2222,
            username: "admin",
            authMethod: .key(path: "~/.ssh/id_rsa"),
            remotePath: "/home/admin",
            group: "Lab"
        )

        let data = try JSONEncoder().encode(fav)
        let decoded = try JSONDecoder().decode(Favorite.self, from: data)

        XCTAssertEqual(decoded.name, fav.name)
        XCTAssertEqual(decoded.host, fav.host)
        XCTAssertEqual(decoded.port, fav.port)
        XCTAssertEqual(decoded.username, fav.username)
        XCTAssertEqual(decoded.authMethod, fav.authMethod)
        XCTAssertEqual(decoded.remotePath, fav.remotePath)
        XCTAssertEqual(decoded.group, fav.group)
        XCTAssertEqual(decoded.id, fav.id)
    }

    func testCodableRoundTripPasswordAuth() throws {
        let fav = Favorite(name: "SW", host: "10.0.0.1", authMethod: .password)
        let data = try JSONEncoder().encode(fav)
        let decoded = try JSONDecoder().decode(Favorite.self, from: data)
        XCTAssertEqual(decoded.authMethod, .password)
    }

    func testCodableRoundTripAgentAuth() throws {
        let fav = Favorite(name: "SW", host: "10.0.0.1", authMethod: .agent)
        let data = try JSONEncoder().encode(fav)
        let decoded = try JSONDecoder().decode(Favorite.self, from: data)
        XCTAssertEqual(decoded.authMethod, .agent)
    }

    // MARK: - Hashable / Equatable

    func testEqualityUsesAllFields() {
        let id = UUID()
        let fav1 = Favorite(id: id, name: "A", host: "1.1.1.1")
        let fav2 = Favorite(id: id, name: "A", host: "1.1.1.1")
        let fav3 = Favorite(id: id, name: "B", host: "2.2.2.2")

        XCTAssertEqual(fav1, fav2)    // identical = equal
        XCTAssertNotEqual(fav1, fav3) // different fields = not equal
    }
}
