import Foundation

@Observable
class BackupScheduler {
    var jobs: [BackupJob] = []
    var results: [BackupResult] = []
    var runningJobIDs: Set<UUID> = []

    private var timers: [UUID: Timer] = [:]
    private let jobsURL: URL
    private let resultsURL: URL
    private let favoritesStore: FavoritesStore
    private let settings: AppSettings

    var backupDir: URL {
        URL(fileURLWithPath: settings.backupDirectory, isDirectory: true)
    }

    init(favoritesStore: FavoritesStore, settings: AppSettings) {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("NetDrop", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        self.jobsURL = appDir.appendingPathComponent("backup_jobs.json")
        self.resultsURL = appDir.appendingPathComponent("backup_results.json")
        self.favoritesStore = favoritesStore
        self.settings = settings

        try? FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)

        loadJobs()
        loadResults()
        startAllTimers()
    }

    // MARK: - CRUD

    func addJob(_ job: BackupJob) {
        jobs.append(job)
        saveJobs()
        if job.isEnabled {
            startTimer(for: job)
        }
    }

    func updateJob(_ job: BackupJob) {
        if let idx = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[idx] = job
            saveJobs()
            stopTimer(for: job.id)
            if job.isEnabled {
                startTimer(for: job)
            }
        }
    }

    func deleteJob(_ job: BackupJob) {
        stopTimer(for: job.id)
        jobs.removeAll { $0.id == job.id }
        saveJobs()
    }

    func toggleJob(_ job: BackupJob) {
        var updated = job
        updated.isEnabled.toggle()
        updateJob(updated)
    }

    // MARK: - Run

    func runNow(_ job: BackupJob) {
        guard !runningJobIDs.contains(job.id) else { return }
        runningJobIDs.insert(job.id)

        Task {
            await executeBackup(job)
            await MainActor.run {
                runningJobIDs.remove(job.id)
            }
        }
    }

    private func executeBackup(_ job: BackupJob) async {
        let favorites = favoritesStore.favorites.filter { job.favorites.contains($0.id) }
        let useLegacySCP = job.deviceType == .fortigate

        for favorite in favorites {
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let safeName = favorite.name.replacingOccurrences(of: "/", with: "_")
            let fileName = "\(safeName)_\(timestamp).conf"
            let filePath = backupDir.appendingPathComponent(fileName)

            do {
                let result = try await SCPService.download(
                    remotePath: job.remotePath,
                    localPath: filePath.path,
                    favorite: favorite,
                    legacySCP: useLegacySCP
                )

                if result.exitCode == 0 {
                    let backupResult = BackupResult(
                        jobID: job.id,
                        jobName: job.name,
                        favoriteID: favorite.id,
                        favoriteName: favorite.name,
                        host: favorite.host,
                        status: .success,
                        filePath: filePath.path
                    )
                    await MainActor.run {
                        results.insert(backupResult, at: 0)
                    }
                } else {
                    let backupResult = BackupResult(
                        jobID: job.id,
                        jobName: job.name,
                        favoriteID: favorite.id,
                        favoriteName: favorite.name,
                        host: favorite.host,
                        status: .failed,
                        errorMessage: ConnectionTester.friendlyError(from: result.output, authMethod: favorite.authMethod)
                    )
                    await MainActor.run {
                        results.insert(backupResult, at: 0)
                    }
                }
            } catch {
                let backupResult = BackupResult(
                    jobID: job.id,
                    jobName: job.name,
                    favoriteID: favorite.id,
                    favoriteName: favorite.name,
                    host: favorite.host,
                    status: .failed,
                    errorMessage: error.localizedDescription
                )
                await MainActor.run {
                    results.insert(backupResult, at: 0)
                }
            }
        }

        // Update job last run
        await MainActor.run {
            if let idx = jobs.firstIndex(where: { $0.id == job.id }) {
                jobs[idx].lastRun = Date()
                let statuses = results.filter { $0.jobID == job.id && $0.timestamp > Date().addingTimeInterval(-5) }
                if statuses.allSatisfy({ $0.status == .success }) {
                    jobs[idx].lastStatus = .success
                } else if statuses.allSatisfy({ $0.status == .failed }) {
                    jobs[idx].lastStatus = .failed
                } else {
                    jobs[idx].lastStatus = .partial
                }
                saveJobs()
                saveResults()
            }
        }
    }

    // MARK: - Timers

    private func startAllTimers() {
        for job in jobs where job.isEnabled {
            startTimer(for: job)
        }
    }

    private func startTimer(for job: BackupJob) {
        let interval = TimeInterval(job.intervalMinutes * 60)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            if let self, let current = self.jobs.first(where: { $0.id == job.id }), current.isEnabled {
                self.runNow(current)
            }
        }
        timers[job.id] = timer
    }

    private func stopTimer(for jobID: UUID) {
        timers[jobID]?.invalidate()
        timers.removeValue(forKey: jobID)
    }

    // MARK: - Persistence

    private func loadJobs() {
        guard FileManager.default.fileExists(atPath: jobsURL.path) else { return }
        if let data = try? Data(contentsOf: jobsURL) {
            jobs = (try? JSONDecoder().decode([BackupJob].self, from: data)) ?? []
        }
    }

    private func saveJobs() {
        if let data = try? JSONEncoder().encode(jobs) {
            try? data.write(to: jobsURL, options: .atomic)
        }
    }

    private func loadResults() {
        guard FileManager.default.fileExists(atPath: resultsURL.path) else { return }
        if let data = try? Data(contentsOf: resultsURL) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            results = (try? decoder.decode([BackupResult].self, from: data)) ?? []
        }
    }

    private func saveResults() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(results) {
            try? data.write(to: resultsURL, options: .atomic)
        }
    }

    // MARK: - Restore

    /// Restore a config file to a device via SCP upload.
    /// For FortiGate: uploads to `fgt-restore-config` which triggers an immediate reboot.
    func restoreConfig(
        localPath: String,
        favorite: Favorite,
        deviceType: DeviceType
    ) async throws -> (output: String, exitCode: Int32) {
        let restorePath: String
        let useLegacySCP: Bool

        switch deviceType {
        case .fortigate:
            restorePath = "fgt-restore-config"
            useLegacySCP = true
        case .generic:
            restorePath = favorite.remotePath
            useLegacySCP = false
        }

        return try await SCPService.upload(
            localPath: localPath,
            remotePath: restorePath,
            favorite: favorite,
            legacySCP: useLegacySCP
        )
    }

    /// Get backup file contents for diff
    func readBackupFile(at path: String) -> String? {
        try? String(contentsOfFile: path, encoding: .utf8)
    }

    /// Get all backup files for a specific favorite, sorted newest first
    func backupsForFavorite(_ favoriteID: UUID) -> [BackupResult] {
        results.filter { $0.favoriteID == favoriteID && $0.status == .success }
    }
}
