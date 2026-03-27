import Foundation

enum DeviceType: String, Codable, CaseIterable {
    case fortigate = "FortiGate"
    case generic = "Generic (SCP path)"

    /// Default remote path for config backup via SCP
    var defaultRemotePath: String {
        switch self {
        case .fortigate: return "sys_config"
        case .generic: return "/etc/config"
        }
    }
}

struct BackupJob: Identifiable, Codable {
    var id: UUID
    var name: String
    var favorites: [UUID]  // IDs of favorites to back up
    var remotePath: String  // Remote file path to download via SCP
    var deviceType: DeviceType
    var intervalMinutes: Int
    var isEnabled: Bool
    var lastRun: Date?
    var lastStatus: BackupStatus?

    // Legacy support
    var remoteCommand: String {
        get { remotePath }
        set { remotePath = newValue }
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        favorites: [UUID] = [],
        remotePath: String = "sys_config",
        deviceType: DeviceType = .fortigate,
        intervalMinutes: Int = 60,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.favorites = favorites
        self.remotePath = remotePath
        self.deviceType = deviceType
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
