import Foundation

/// Represents a live in-flight transfer with process handle
@Observable
class TransferTask: Identifiable {
    let id: UUID
    let favorite: Favorite
    let direction: TransferDirection
    let localPath: String
    let remotePath: String

    var status: TransferStatus = .inProgress
    var progressText: String = ""
    var errorMessage: String?

    private var process: Process?

    init(
        id: UUID = UUID(),
        favorite: Favorite,
        direction: TransferDirection,
        localPath: String,
        remotePath: String
    ) {
        self.id = id
        self.favorite = favorite
        self.direction = direction
        self.localPath = localPath
        self.remotePath = remotePath
    }

    func cancel() {
        process?.terminate()
        status = .cancelled
    }

    func attachProcess(_ process: Process) {
        self.process = process
    }
}
