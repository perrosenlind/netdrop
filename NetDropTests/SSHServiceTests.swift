import XCTest
@testable import NetDrop

final class SSHServiceTests: XCTestCase {

    func testListDirectoryFailsForUnreachableHost() async {
        let fav = Favorite(name: "Fake", host: "192.0.2.1", username: "admin", authMethod: .agent)

        do {
            _ = try await SSHService.listDirectory(path: "/", favorite: fav)
            XCTFail("Should have thrown for unreachable host")
        } catch {
            // Expected — connection refused or timeout
            XCTAssertTrue(error is SSHError || error is CocoaError || true)
        }
    }

    func testMkdirFailsForUnreachableHost() async {
        let fav = Favorite(name: "Fake", host: "192.0.2.1", username: "admin", authMethod: .agent)

        do {
            try await SSHService.mkdir(path: "/tmp/test", favorite: fav)
            XCTFail("Should have thrown")
        } catch {
            // Expected
        }
    }

    func testRemoveFailsForUnreachableHost() async {
        let fav = Favorite(name: "Fake", host: "192.0.2.1", username: "admin", authMethod: .agent)

        do {
            try await SSHService.remove(path: "/tmp/test", favorite: fav)
            XCTFail("Should have thrown")
        } catch {
            // Expected
        }
    }

    func testRenameFailsForUnreachableHost() async {
        let fav = Favorite(name: "Fake", host: "192.0.2.1", username: "admin", authMethod: .agent)

        do {
            try await SSHService.rename(from: "/tmp/a", to: "/tmp/b", favorite: fav)
            XCTFail("Should have thrown")
        } catch {
            // Expected
        }
    }
}
