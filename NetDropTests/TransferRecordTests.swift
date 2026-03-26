import XCTest
@testable import NetDrop

final class TransferRecordTests: XCTestCase {

    func testDefaultStatus() {
        let record = TransferRecord(favoriteName: "FW", host: "10.0.0.1", direction: .upload, localPath: "/a", remotePath: "/b")
        XCTAssertEqual(record.status, .inProgress)
        XCTAssertNil(record.completedAt)
        XCTAssertNil(record.errorMessage)
    }

    func testCodableRoundTrip() throws {
        var record = TransferRecord(favoriteName: "FW", host: "10.0.0.1", direction: .download, localPath: "/tmp/a", remotePath: "/b")
        record.completedAt = Date()
        record.status = .completed
        record.bytesTransferred = 1024

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TransferRecord.self, from: data)

        XCTAssertEqual(decoded.favoriteName, "FW")
        XCTAssertEqual(decoded.host, "10.0.0.1")
        XCTAssertEqual(decoded.direction, .download)
        XCTAssertEqual(decoded.status, .completed)
        XCTAssertEqual(decoded.bytesTransferred, 1024)
        XCTAssertNotNil(decoded.completedAt)
    }

    func testAllDirections() {
        let up = TransferRecord(favoriteName: "FW", host: "10.0.0.1", direction: .upload, localPath: "/a", remotePath: "/b")
        let down = TransferRecord(favoriteName: "FW", host: "10.0.0.1", direction: .download, localPath: "/a", remotePath: "/b")
        XCTAssertEqual(up.direction, .upload)
        XCTAssertEqual(down.direction, .download)
    }

    func testAllStatuses() {
        let statuses: [TransferStatus] = [.inProgress, .completed, .failed, .cancelled]
        for status in statuses {
            var record = TransferRecord(favoriteName: "FW", host: "10.0.0.1", direction: .upload, localPath: "/a", remotePath: "/b")
            record.status = status
            XCTAssertEqual(record.status, status)
        }
    }
}
