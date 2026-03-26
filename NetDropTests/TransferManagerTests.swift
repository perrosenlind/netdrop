import XCTest
@testable import NetDrop

final class TransferManagerTests: XCTestCase {

    // MARK: - Task creation

    func testUploadCreatesTask() {
        let manager = TransferManager()
        let fav = Favorite(name: "Test", host: "192.168.1.1", username: "admin")

        let task = manager.upload(localPath: "/tmp/test.bin", remotePath: "/upload/test.bin", favorite: fav)

        XCTAssertEqual(task.direction, .upload)
        XCTAssertEqual(task.localPath, "/tmp/test.bin")
        XCTAssertEqual(task.remotePath, "/upload/test.bin")
        XCTAssertEqual(task.favorite.host, "192.168.1.1")
        XCTAssertTrue(manager.activeTasks.contains(where: { $0.id == task.id }))
    }

    func testDownloadCreatesTask() {
        let manager = TransferManager()
        let fav = Favorite(name: "Test", host: "192.168.1.1", username: "admin")

        let task = manager.download(remotePath: "/config.conf", localPath: "/tmp/config.conf", favorite: fav)

        XCTAssertEqual(task.direction, .download)
        XCTAssertEqual(task.localPath, "/tmp/config.conf")
        XCTAssertEqual(task.remotePath, "/config.conf")
    }

    // MARK: - Multi-file upload

    func testUploadMultipleCreatesTaskPerFile() {
        let manager = TransferManager()
        let fav = Favorite(name: "FW", host: "10.0.0.1", username: "admin", remotePath: "/upload/")

        let before = manager.activeTasks.count
        manager.uploadMultiple(localPaths: ["/tmp/a.bin", "/tmp/b.bin", "/tmp/c.bin"],
                               remotePath: "/upload/",
                               favorite: fav)

        XCTAssertEqual(manager.activeTasks.count, before + 3)
    }

    // MARK: - Multi-destination upload

    func testUploadToMultipleDestinations() {
        let manager = TransferManager()
        let fav1 = Favorite(name: "FW1", host: "10.0.0.1", username: "admin", remotePath: "/")
        let fav2 = Favorite(name: "FW2", host: "10.0.0.2", username: "admin", remotePath: "/")

        let before = manager.activeTasks.count
        manager.uploadToMultipleDestinations(
            localPaths: ["/tmp/firmware.bin"],
            favorites: [fav1, fav2]
        )

        // 1 file x 2 destinations = 2 tasks
        XCTAssertEqual(manager.activeTasks.count, before + 2)
    }

    func testUploadMultiFileMultiDestination() {
        let manager = TransferManager()
        let fav1 = Favorite(name: "FW1", host: "10.0.0.1", username: "admin", remotePath: "/")
        let fav2 = Favorite(name: "FW2", host: "10.0.0.2", username: "admin", remotePath: "/")

        let before = manager.activeTasks.count
        manager.uploadToMultipleDestinations(
            localPaths: ["/tmp/a.bin", "/tmp/b.bin"],
            favorites: [fav1, fav2]
        )

        // 2 files x 2 destinations = 4 tasks
        XCTAssertEqual(manager.activeTasks.count, before + 4)
    }

    // MARK: - Cancel

    func testCancelTask() {
        let manager = TransferManager()
        let fav = Favorite(name: "Test", host: "192.168.1.1", username: "admin")
        let task = manager.upload(localPath: "/tmp/test.bin", remotePath: "/test.bin", favorite: fav)

        manager.cancelTask(task)

        XCTAssertEqual(task.status, .cancelled)
    }

    // MARK: - Clear completed

    func testClearCompletedRemovesFinishedTasks() {
        let manager = TransferManager()
        let fav = Favorite(name: "Test", host: "192.168.1.1", username: "admin")

        let task1 = manager.upload(localPath: "/tmp/a.bin", remotePath: "/a.bin", favorite: fav)
        let task2 = manager.upload(localPath: "/tmp/b.bin", remotePath: "/b.bin", favorite: fav)

        // Simulate completion
        task1.status = .completed
        task2.status = .inProgress

        manager.clearCompleted()

        XCTAssertFalse(manager.activeTasks.contains(where: { $0.id == task1.id }))
        XCTAssertTrue(manager.activeTasks.contains(where: { $0.id == task2.id }))
    }
}
