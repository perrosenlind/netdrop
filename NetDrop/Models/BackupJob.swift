import Foundation

struct BackupJob: Identifiable, Codable {
    var id: UUID
    var name: String
    var favorites: [UUID]  // IDs of favorites to back up
    var remoteCommand: String  // Command to run (e.g. "cat /etc/config" or path to download)
    var intervalMinutes: Int
    var isEnabled: Bool
    var lastRun: Date?
    var lastStatus: BackupStatus?

    init(
        id: UUID = UUID(),
        name: String = "",
        favorites: [UUID] = [],
        remoteCommand: String = "show full-configuration",
        intervalMinutes: Int = 60,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.favorites = favorites
        self.remoteCommand = remoteCommand
        self.intervalMinutes = intervalMinutes
        self.isEnabled = isEnabled
    }
}

enum BackupStatus: String, Codable {
    case success
    case partial  // some devices succeeded, some failed
    case failed
}

struct BackupResult: Identifiable, Codable {
    let id: UUID
    let jobID: UUID
    let jobName: String
    let favoriteID: UUID
    let favoriteName: String
    let host: String
    let timestamp: Date
    let status: BackupStatus
    let filePath: String?  // local path where config was saved
    let errorMessage: String?

    init(
        id: UUID = UUID(),
        jobID: UUID,
        jobName: String,
        favoriteID: UUID,
        favoriteName: String,
        host: String,
        timestamp: Date = Date(),
        status: BackupStatus,
        filePath: String? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.jobID = jobID
        self.jobName = jobName
        self.favoriteID = favoriteID
        self.favoriteName = favoriteName
        self.host = host
        self.timestamp = timestamp
        self.status = status
        self.filePath = filePath
        self.errorMessage = errorMessage
    }
}
