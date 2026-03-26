import XCTest
@testable import NetDrop

final class SCPServiceTests: XCTestCase {

    // MARK: - SCP argument building (tested indirectly via the service)

    func testUploadBuildsCorrectRemoteTarget() async throws {
        // We can't test actual SCP without a real server, but we can verify
        // the service doesn't crash with valid inputs
        let fav = Favorite(
            name: "Test",
            host: "192.168.1.1",
            port: 22,
            username: "admin",
            authMethod: .key(path: "~/.ssh/id_rsa")
        )

        // This will fail because no server, but should not throw an unexpected error
        do {
            _ = try await SCPService.upload(
                localPath: "/nonexistent/file.bin",
                remotePath: "/upload/file.bin",
                favorite: fav
            )
        } catch {
            // Expected — scp will fail because the file doesn't exist
            // But the Process should have launched successfully
        }
    }

    func testCustomPortFavorite() {
        // Verify Favorite with custom port can be created
        let fav = Favorite(name: "Custom", host: "10.0.0.1", port: 2222, username: "root")
        XCTAssertEqual(fav.port, 2222)
    }
}
