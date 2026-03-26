import Foundation

struct TransferRecord: Identifiable, Codable {
    var id: UUID
    var favoriteName: String
    var host: String
    var direction: TransferDirection
    var localPath: String
    var remotePath: String
    var status: TransferStatus
    var startedAt: Date
    var completedAt: Date?
    var bytesTransferred: Int64?
    var errorMessage: String?

    init(
        id: UUID = UUID(),
        favoriteName: String,
        host: String,
        direction: TransferDirection,
        localPath: String,
        remotePath: String,
        status: TransferStatus = .inProgress,
        startedAt: Date = Date()
    ) {
        self.id = id
        self.favoriteName = favoriteName
        self.host = host
        self.direction = direction
        self.localPath = localPath
        self.remotePath = remotePath
        self.status = status
        self.startedAt = startedAt
    }
}

enum TransferDirection: String, Codable {
    case upload
    case download
}

enum TransferStatus: String, Codable {
    case inProgress
    case completed
    case failed
    case cancelled
}
