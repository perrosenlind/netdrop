import XCTest
@testable import NetDrop

final class TransferTaskTests: XCTestCase {

    func testInitialStatus() {
        let fav = Favorite(name: "FW", host: "10.0.0.1")
        let task = TransferTask(favorite: fav, direction: .upload, localPath: "/a", remotePath: "/b")

        XCTAssertEqual(task.status, .inProgress)
        XCTAssertEqual(task.progressText, "")
        XCTAssertNil(task.errorMessage)
    }

    func testCancel() {
        let fav = Favorite(name: "FW", host: "10.0.0.1")
        let task = TransferTask(favorite: fav, direction: .upload, localPath: "/a", remotePath: "/b")

        task.cancel()

        XCTAssertEqual(task.status, .cancelled)
    }

    func testAttachProcess() {
        let fav = Favorite(name: "FW", host: "10.0.0.1")
        let task = TransferTask(favorite: fav, direction: .download, localPath: "/a", remotePath: "/b")

        let process = Process()
        task.attachProcess(process) // Should not crash
    }

    func testPropertiesMatchInit() {
        let fav = Favorite(name: "Switch", host: "172.16.0.1")
        let task = TransferTask(
            favorite: fav,
            direction: .download,
            localPath: "/tmp/config.conf",
            remotePath: "/etc/config.conf"
        )

        XCTAssertEqual(task.favorite.name, "Switch")
        XCTAssertEqual(task.direction, .download)
        XCTAssertEqual(task.localPath, "/tmp/config.conf")
        XCTAssertEqual(task.remotePath, "/etc/config.conf")
    }
}
