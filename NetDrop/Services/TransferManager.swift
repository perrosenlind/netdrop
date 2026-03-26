import Foundation
import UserNotifications

@Observable
class TransferManager {
    var activeTasks: [TransferTask] = []
    var history: [TransferRecord] = []

    private let historyURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("NetDrop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.historyURL = appDir.appendingPathComponent("history.json")
        loadHistory()
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Single transfers

    @discardableResult
    func upload(localPath: String, remotePath: String, favorite: Favorite) -> TransferTask {
        let task = TransferTask(
            favorite: favorite,
            direction: .upload,
            localPath: localPath,
            remotePath: remotePath
        )
        activeTasks.append(task)
        Task { await performTransfer(task: task) }
        return task
    }

    @discardableResult
    func download(remotePath: String, localPath: String, favorite: Favorite) -> TransferTask {
        let task = TransferTask(
            favorite: favorite,
            direction: .download,
            localPath: localPath,
            remotePath: remotePath
        )
        activeTasks.append(task)
        Task { await performTransfer(task: task) }
        return task
    }

    // MARK: - Multi-file upload

    func uploadMultiple(localPaths: [String], remotePath: String, favorite: Favorite) {
        for localPath in localPaths {
            let fileName = (localPath as NSString).lastPathComponent
            let fullRemote = remotePath.hasSuffix("/") ? remotePath + fileName : remotePath + "/" + fileName
            upload(localPath: localPath, remotePath: fullRemote, favorite: favorite)
        }
    }

    // MARK: - Multi-destination upload

    func uploadToMultipleDestinations(localPaths: [String], favorites: [Favorite]) {
        for favorite in favorites {
            let remotePath = favorite.remotePath
            for localPath in localPaths {
                let fileName = (localPath as NSString).lastPathComponent
                let fullRemote = remotePath.hasSuffix("/") ? remotePath + fileName : remotePath + "/" + fileName
                upload(localPath: localPath, remotePath: fullRemote, favorite: favorite)
            }
        }
    }

    // MARK: - Task management

    func cancelTask(_ task: TransferTask) {
        task.cancel()
        recordCompletion(task: task)
    }

    func clearCompleted() {
        activeTasks.removeAll { $0.status != .inProgress }
    }

    // MARK: - Transfer execution

    private func performTransfer(task: TransferTask) async {
        let onProgress: @Sendable (String) -> Void = { [weak task] progressLine in
            Task { @MainActor in
                task?.progressText = progressLine
            }
        }

        do {
            let result: (output: String, exitCode: Int32)

            switch task.direction {
            case .upload:
                result = try await SCPService.upload(
                    localPath: task.localPath,
                    remotePath: task.remotePath,
                    favorite: task.favorite,
                    onProgress: onProgress
                )
            case .download:
                result = try await SCPService.download(
                    remotePath: task.remotePath,
                    localPath: task.localPath,
                    favorite: task.favorite,
                    onProgress: onProgress
                )
            }

            await MainActor.run {
                let fileName = (task.localPath as NSString).lastPathComponent
                if result.exitCode == 0 {
                    task.status = .completed
                    task.progressText = "Complete"
                    sendNotification(
                        title: "Transfer Complete",
                        body: "\(fileName) → \(task.favorite.name)"
                    )
                } else {
                    task.status = .failed
                    task.errorMessage = result.output
                    task.progressText = "Failed"
                    sendNotification(
                        title: "Transfer Failed",
                        body: "\(fileName) → \(task.favorite.name)"
                    )
                }
                recordCompletion(task: task)
            }
        } catch {
            await MainActor.run {
                task.status = .failed
                task.errorMessage = error.localizedDescription
                task.progressText = "Failed"
                recordCompletion(task: task)
            }
        }
    }

    private func recordCompletion(task: TransferTask) {
        var record = TransferRecord(
            favoriteName: task.favorite.name,
            host: task.favorite.host,
            direction: task.direction,
            localPath: task.localPath,
            remotePath: task.remotePath,
            status: task.status
        )
        record.completedAt = Date()
        record.errorMessage = task.errorMessage
        history.insert(record, at: 0)
        saveHistory()
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyURL.path) else { return }
        do {
            let data = try Data(contentsOf: historyURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            history = try decoder.decode([TransferRecord].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(history)
            try data.write(to: historyURL, options: .atomic)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}
