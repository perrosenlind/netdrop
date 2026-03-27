import SwiftUI

struct ConfigViewerItem: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

struct BackupSchedulerView: View {
    @Environment(BackupScheduler.self) private var scheduler
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingAddJob = false
    @State private var editingJob: BackupJob?
    @State private var restoreResult: BackupResult?
    @State private var showingRestoreConfirm = false
    @State private var restoreStatus: String?
    @State private var viewingConfig: ConfigViewerItem?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Config Backup Scheduler")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddJob = true
                } label: {
                    Label("Add Job", systemImage: "plus")
                }
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .help("Close")
                .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            if scheduler.jobs.isEmpty {
                ContentUnavailableView(
                    "No Backup Jobs",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Schedule automatic config backups from your devices.")
                )
            } else {
                List {
                    Section("Jobs") {
                        ForEach(scheduler.jobs) { job in
                            BackupJobRow(job: job)
                                .contextMenu {
                                    Button("Edit…") { editingJob = job }
                                    Button("Run Now") { scheduler.runNow(job) }
                                    Button(job.isEnabled ? "Disable" : "Enable") { scheduler.toggleJob(job) }
                                    Divider()
                                    Button("Delete", role: .destructive) { scheduler.deleteJob(job) }
                                }
                        }
                    }

                    if !scheduler.results.isEmpty {
                        Section("Recent Results") {
                            ForEach(scheduler.results.prefix(20)) { result in
                                BackupResultRow(result: result)
                                    .contextMenu {
                                        if result.status == .success, let path = result.filePath {
                                            Button("View Config") {
                                                if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                                                    viewingConfig = ConfigViewerItem(
                                                        title: "\(result.favoriteName) — \(result.timestamp.formatted())",
                                                        content: content
                                                    )
                                                }
                                            }
                                            Button("Show in Finder") {
                                                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                                            }
                                            Divider()
                                            Button("Restore to Device…") {
                                                restoreResult = result
                                                showingRestoreConfirm = true
                                            }
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }

            if let restoreStatus {
                HStack {
                    Image(systemName: restoreStatus.starts(with: "Error") ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(restoreStatus.starts(with: "Error") ? .red : .green)
                    Text(restoreStatus)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") { self.restoreStatus = nil }
                        .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.bar)
            }
        }
        .alert("Restore Config", isPresented: $showingRestoreConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                performRestore()
            }
        } message: {
            if let result = restoreResult {
                let job = scheduler.jobs.first(where: { $0.id == result.jobID })
                let isFortigate = job?.deviceType == .fortigate
                Text(isFortigate
                    ? "This will upload the config to \(result.favoriteName) (\(result.host)). The FortiGate will reboot immediately after upload. Continue?"
                    : "This will upload the config to \(result.favoriteName) (\(result.host)). Continue?")
            }
        }
        .sheet(isPresented: $showingAddJob) {
            BackupJobEditView(mode: .add)
        }
        .sheet(item: $editingJob) { job in
            BackupJobEditView(mode: .edit(job))
        }
        .sheet(item: $viewingConfig) { item in
            ConfigViewerView(title: item.title, content: item.content)
        }
    }

    private func performRestore() {
        guard let result = restoreResult,
              let filePath = result.filePath,
              let favorite = favoritesStore.favorites.first(where: { $0.id == result.favoriteID }) else {
            restoreStatus = "Error: could not find device or backup file"
            return
        }

        let job = scheduler.jobs.first(where: { $0.id == result.jobID })
        let deviceType = job?.deviceType ?? .generic

        restoreStatus = "Restoring to \(favorite.name)…"

        Task {
            do {
                let scpResult = try await scheduler.restoreConfig(
                    localPath: filePath,
                    favorite: favorite,
                    deviceType: deviceType
                )

                await MainActor.run {
                    if scpResult.exitCode == 0 {
                        let msg = deviceType == .fortigate
                            ? "Config restored to \(favorite.name). Device is rebooting."
                            : "Config restored to \(favorite.name)."
                        restoreStatus = msg
                    } else {
                        restoreStatus = "Error: \(ConnectionTester.friendlyError(from: scpResult.output, authMethod: favorite.authMethod))"
                    }
                }
            } catch {
                await MainActor.run {
                    restoreStatus = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct BackupJobRow: View {
    @Environment(BackupScheduler.self) private var scheduler
    let job: BackupJob

    var body: some View {
        HStack {
            Image(systemName: job.isEnabled ? "clock.fill" : "clock")
                .foregroundColor(job.isEnabled ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(job.name)
                        .fontWeight(.medium)
                    if !job.isEnabled {
                        Text("Disabled")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    if scheduler.runningJobIDs.contains(job.id) {
                        ProgressView()
                            .controlSize(.mini)
                    }
                }
                Text("\(job.favorites.count) device(s) · \(job.deviceType.rawValue) · every \(job.intervalMinutes) min")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let lastRun = job.lastRun {
                    HStack(spacing: 4) {
                        statusIcon(job.lastStatus)
                        Text("Last: \(lastRun, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Button("Run") {
                scheduler.runNow(job)
            }
            .controlSize(.small)
            .disabled(scheduler.runningJobIDs.contains(job.id))
        }
    }

    @ViewBuilder
    private func statusIcon(_ status: BackupStatus?) -> some View {
        switch status {
        case .success:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.caption2)
        case .partial:
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.caption2)
        case .failed:
            Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.caption2)
        case nil:
            EmptyView()
        }
    }
}

struct BackupResultRow: View {
    let result: BackupResult

    var body: some View {
        HStack {
            Image(systemName: result.status == .success ? "checkmark.circle" : "xmark.circle")
                .foregroundColor(result.status == .success ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(result.favoriteName) (\(result.host))")
                    .font(.body)
                Text(result.jobName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let error = result.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(result.timestamp, style: .relative)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Edit View

enum BackupJobEditMode: Identifiable {
    case add
    case edit(BackupJob)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let job): return job.id.uuidString
        }
    }
}

struct BackupJobEditView: View {
    @Environment(BackupScheduler.self) private var scheduler
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(\.dismiss) private var dismiss

    let mode: BackupJobEditMode

    @State private var name = ""
    @State private var remotePath = "sys_config"
    @State private var deviceType: DeviceType = .fortigate
    @State private var intervalMinutes = 60
    @State private var selectedFavoriteIDs: Set<UUID> = []

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Job") {
                    TextField("Name", text: $name)
                    Picker("Device type", selection: $deviceType) {
                        ForEach(DeviceType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: deviceType) { _, newType in
                        remotePath = newType.defaultRemotePath
                    }
                    TextField("Remote path (SCP)", text: $remotePath)
                        .font(.system(.body, design: .monospaced))
                    if deviceType == .fortigate {
                        Text("FortiGate: downloads sys_config via SCP with legacy protocol (-O)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Picker("Interval", selection: $intervalMinutes) {
                        Text("Every 15 min").tag(15)
                        Text("Every 30 min").tag(30)
                        Text("Every hour").tag(60)
                        Text("Every 6 hours").tag(360)
                        Text("Every 12 hours").tag(720)
                        Text("Daily").tag(1440)
                    }
                }

                Section("Devices") {
                    ForEach(favoritesStore.favorites) { fav in
                        HStack {
                            Image(systemName: selectedFavoriteIDs.contains(fav.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedFavoriteIDs.contains(fav.id) ? .accentColor : .secondary)
                            FavoriteRow(favorite: fav)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedFavoriteIDs.contains(fav.id) {
                                selectedFavoriteIDs.remove(fav.id)
                            } else {
                                selectedFavoriteIDs.insert(fav.id)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .frame(width: 450, height: 400)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(isEditing ? "Save" : "Create") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty || selectedFavoriteIDs.isEmpty)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear {
            if case .edit(let job) = mode {
                name = job.name
                remotePath = job.remotePath
                deviceType = job.deviceType
                intervalMinutes = job.intervalMinutes
                selectedFavoriteIDs = Set(job.favorites)
            }
        }
    }

    private func save() {
        var job: BackupJob
        if case .edit(let existing) = mode {
            job = existing
        } else {
            job = BackupJob()
        }
        job.name = name
        job.remotePath = remotePath
        job.deviceType = deviceType
        job.intervalMinutes = intervalMinutes
        job.favorites = Array(selectedFavoriteIDs)

        if isEditing {
            scheduler.updateJob(job)
        } else {
            scheduler.addJob(job)
        }
        dismiss()
    }
}
