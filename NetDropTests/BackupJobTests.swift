import XCTest
@testable import NetDrop

final class BackupJobTests: XCTestCase {

    func testDefaultValues() {
        let job = BackupJob()
        XCTAssertEqual(job.remoteCommand, "show full-configuration")
        XCTAssertEqual(job.intervalMinutes, 60)
        XCTAssertTrue(job.isEnabled)
        XCTAssertNil(job.lastRun)
        XCTAssertNil(job.lastStatus)
        XCTAssertTrue(job.favorites.isEmpty)
    }

    func testCodableRoundTrip() throws {
        var job = BackupJob(
            name: "Daily Backup",
            favorites: [UUID(), UUID()],
            remoteCommand: "cat /etc/config",
            intervalMinutes: 360,
            isEnabled: false
        )
        job.lastRun = Date()
        job.lastStatus = .success

        let data = try JSONEncoder().encode(job)
        let decoded = try JSONDecoder().decode(BackupJob.self, from: data)

        XCTAssertEqual(decoded.name, "Daily Backup")
        XCTAssertEqual(decoded.favorites.count, 2)
        XCTAssertEqual(decoded.remoteCommand, "cat /etc/config")
        XCTAssertEqual(decoded.intervalMinutes, 360)
        XCTAssertFalse(decoded.isEnabled)
        XCTAssertNotNil(decoded.lastRun)
        XCTAssertEqual(decoded.lastStatus, .success)
    }

    func testBackupResultCodable() throws {
        let result = BackupResult(
            jobID: UUID(),
            jobName: "Test",
            favoriteID: UUID(),
            favoriteName: "FW-01",
            host: "10.0.0.1",
            status: .failed,
            errorMessage: "Connection refused"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(result)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(BackupResult.self, from: data)

        XCTAssertEqual(decoded.jobName, "Test")
        XCTAssertEqual(decoded.favoriteName, "FW-01")
        XCTAssertEqual(decoded.status, .failed)
        XCTAssertEqual(decoded.errorMessage, "Connection refused")
    }

    func testAllStatuses() throws {
        for status in [BackupStatus.success, .partial, .failed] {
            let result = BackupResult(
                jobID: UUID(), jobName: "T", favoriteID: UUID(),
                favoriteName: "F", host: "1.1.1.1", status: status
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(result)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(BackupResult.self, from: data)
            XCTAssertEqual(decoded.status, status)
        }
    }
}
