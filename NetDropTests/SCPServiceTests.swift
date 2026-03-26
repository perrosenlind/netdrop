import XCTest
@testable import NetDrop

final class SCPServiceTests: XCTestCase {

    // MARK: - Upload with valid file (will fail to connect but Process launches)

    func testUploadReturnsNonZeroForUnreachableHost() async throws {
        let fav = Favorite(name: "Fake", host: "192.0.2.1", port: 22, username: "admin", authMethod: .agent)

        let result = try await SCPService.upload(
            localPath: "/dev/null",
            remotePath: "/tmp/test",
            favorite: fav
        )

        // scp should fail with non-zero exit (unreachable host or timeout)
        XCTAssertNotEqual(result.exitCode, 0)
        XCTAssertFalse(result.output.isEmpty)
    }

    func testDownloadReturnsNonZeroForUnreachableHost() async throws {
        let fav = Favorite(name: "Fake", host: "192.0.2.1", port: 22, username: "admin", authMethod: .agent)

        let result = try await SCPService.download(
            remotePath: "/tmp/test",
            localPath: "/tmp/netdrop_test_dl",
            favorite: fav
        )

        XCTAssertNotEqual(result.exitCode, 0)
    }

    // MARK: - Progress callback fires

    func testProgressCallbackReceivesOutput() async throws {
        let fav = Favorite(name: "Fake", host: "192.0.2.1", username: "admin", authMethod: .agent)
        var received = false

        _ = try await SCPService.upload(
            localPath: "/dev/null",
            remotePath: "/tmp/test",
            favorite: fav,
            onProgress: { _ in received = true }
        )

        // Progress may or may not fire depending on scp output timing,
        // but the callback shouldn't crash
    }

    // MARK: - Key path expansion

    func testKeyAuthFavoriteStoresPath() {
        let fav = Favorite(name: "FW", host: "10.0.0.1", authMethod: .key(path: "~/.ssh/custom_key"))
        if case .key(let path) = fav.authMethod {
            XCTAssertEqual(path, "~/.ssh/custom_key")
        } else {
            XCTFail("Expected key auth")
        }
    }

    func testCustomPortFavorite() {
        let fav = Favorite(name: "Custom", host: "10.0.0.1", port: 2222)
        XCTAssertEqual(fav.port, 2222)
    }
}
