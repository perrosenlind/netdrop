import SwiftUI

enum BackupSelection: Hashable {
    case file(BackupFileItem)
    case addJob
}

struct BackupMainView: View {
    @Environment(BackupScheduler.self) private var scheduler
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(AppSettings.self) private var settings

    @State private var selection: BackupSelection?
    @State private var groupedFiles: [String: [BackupFileItem]] = [:]
    @State private var editingJob: BackupJob?
    @State private var showingRestoreConfirm = false
    @State private var restoreFile: BackupFileItem?
    @State private var restoreTarget: Favorite?
    @State private var restoreDeviceType: DeviceType = .fortigate
    @State private var statusMessage: String?

    // Ad-hoc backup state
    @State private var adHocFavorite: Favorite?
    @State private var adHocDeviceType: DeviceType = .fortigate
    @State private var adHocRemotePath: String = "sys_config"
    @State private var adHocRunning = false

    var body: some View {
        HSplitView {
            backupSidebar
                .frame(minWidth: 220, idealWidth: 260, maxWidth: 350)

            backupDetail
                .frame(minWidth: 400)
        }
        .onAppear { refreshFiles() }
    }

    // MARK: - Sidebar

    private var backupSidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Backups")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("New Job…") { selection = .addJob }
                    Button("Refresh") { refreshFiles() }
                    Button("Open in Finder") {
                        NSWorkspace.shared.open(scheduler.backupDir)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Ad-hoc backup section
            adHocBackupSection

            Divider()

            // Jobs section
            jobsSection

            Divider()

            // Files section
            filesBrowser
        }
        .background(.bar)
    }

    private var adHocBackupSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quick Backup")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Picker("Device", selection: $adHocFavorite) {
                Text("Select device…").tag(Favorite?.none)
                ForEach(favoritesStore.favorites) { fav in
                    Text(fav.name).tag(Optional(fav))
                }
            }
            .controlSize(.small)

            HStack(spacing: 4) {
                Picker("", selection: $adHocDeviceType) {
                    ForEach(DeviceType.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .controlSize(.small)
                .frame(maxWidth: 120)
                .onChange(of: adHocDeviceType) { _, t in
                    adHocRemotePath = t.defaultRemotePath
                }

                TextField("Path", text: $adHocRemotePath)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .font(.system(.caption, design: .monospaced))
            }

            Button {
                runAdHocBackup()
            } label: {
                HStack {
                    if adHocRunning {
                        ProgressView().controlSize(.mini)
                    }
                    Text(adHocRunning ? "Backing up…" : "Backup Now")
                }
                .frame(maxWidth: .infinity)
            }
            .controlSize(.small)
            .buttonStyle(.borderedProminent)
            .disabled(adHocFavorite == nil || adHocRunning)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var jobsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Scheduled Jobs")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Button { selection = .addJob } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            if scheduler.jobs.isEmpty {
                Text("No scheduled jobs")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
            } else {
                ForEach(scheduler.jobs) { job in
                    HStack(spacing: 6) {
                        Image(systemName: job.isEnabled ? "clock.fill" : "clock")
                            .foregroundColor(job.isEnabled ? .green : .secondary)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(job.name).font(.caption).fontWeight(.medium)
                            Text("\(job.deviceType.rawValue) · \(job.intervalMinutes)min")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        if scheduler.runningJobIDs.contains(job.id) {
                            ProgressView().controlSize(.mini)
                        }
                        Button("Run") { scheduler.runNow(job) }
                            .controlSize(.mini)
                            .disabled(scheduler.runningJobIDs.contains(job.id))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 3)
                    .contextMenu {
                        Button("Edit…") { editingJob = job }
                        Button("Run Now") { scheduler.runNow(job) }
                        Button(job.isEnabled ? "Disable" : "Enable") { scheduler.toggleJob(job) }
                        Divider()
                        Button("Delete", role: .destructive) { scheduler.deleteJob(job) }
                    }
                }
            }
        }
    }

    private var filesBrowser: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Config Files")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(groupedFiles.values.flatMap { $0 }.count) files")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            List(selection: Binding<BackupSelection?>(
                get: { selection },
                set: { selection = $0 }
            )) {
                if groupedFiles.isEmpty {
                    Text("No backups yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ForEach(groupedFiles.keys.sorted(), id: \.self) { device in
                        Section(device) {
                            ForEach(groupedFiles[device] ?? []) { file in
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(file.formattedDate)
                                            .font(.caption)
                                        Text(file.formattedSize)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .tag(BackupSelection.file(file))
                                .contextMenu {
                                    Button("Show in Finder") {
                                        NSWorkspace.shared.selectFile(file.filePath, inFileViewerRootedAtPath: "")
                                    }
                                    Button("Delete", role: .destructive) {
                                        try? FileManager.default.removeItem(atPath: file.filePath)
                                        refreshFiles()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var backupDetail: some View {
        VStack(spacing: 0) {
            if let statusMessage {
                HStack {
                    Image(systemName: statusMessage.starts(with: "Error") ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(statusMessage.starts(with: "Error") ? .red : .green)
                    Text(statusMessage)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") { self.statusMessage = nil }
                        .controlSize(.mini)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(.bar)
                Divider()
            }

            switch selection {
            case .file(let file):
                BackupFileDetailView(
                    file: file,
                    onRestore: { restoreFile(file) },
                    onRefresh: { refreshFiles() }
                )
            case .addJob:
                BackupJobInlineEditView(mode: .add) {
                    selection = nil
                }
            case nil:
                ContentUnavailableView(
                    "Select a Backup",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Choose a config file from the list, or take a quick backup.")
                )
            }
        }
        .sheet(item: $editingJob) { job in
            BackupJobEditView(mode: .edit(job))
        }
        .alert("Restore Config", isPresented: $showingRestoreConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) { performRestore() }
        } message: {
            if let file = restoreFile, let target = restoreTarget {
                Text(restoreDeviceType == .fortigate
                    ? "Upload \(file.fileName) to \(target.name) (\(target.host))? The FortiGate will reboot immediately."
                    : "Upload \(file.fileName) to \(target.name) (\(target.host))?")
            }
        }
    }

    // MARK: - Actions

    private func refreshFiles() {
        groupedFiles = scheduler.scanBackupFiles()
    }

    private func runAdHocBackup() {
        guard let favorite = adHocFavorite else { return }
        adHocRunning = true
        statusMessage = nil

        Task {
            let result = await scheduler.adHocBackup(
                favorite: favorite,
                remotePath: adHocRemotePath,
                deviceType: adHocDeviceType
            )

            await MainActor.run {
                adHocRunning = false
                if result.success, let path = result.filePath {
                    statusMessage = "Backup saved: \((path as NSString).lastPathComponent)"
                    refreshFiles()
                    // Auto-select the new file
                    if let item = BackupFileItem.parse(url: URL(fileURLWithPath: path)) {
                        selection = .file(item)
                    }
                } else {
                    statusMessage = "Error: \(result.error ?? "Unknown error")"
                }
            }
        }
    }

    private func restoreFile(_ file: BackupFileItem) {
        // Find the favorite that matches this device name
        restoreFile = file
        restoreTarget = favoritesStore.favorites.first(where: { $0.name == file.deviceName })
        restoreDeviceType = .fortigate

        if restoreTarget != nil {
            showingRestoreConfirm = true
        } else {
            statusMessage = "Error: No saved favorite matches device '\(file.deviceName)'"
        }
    }

    private func performRestore() {
        guard let file = restoreFile, let target = restoreTarget else { return }
        statusMessage = "Restoring to \(target.name)…"

        Task {
            do {
                let result = try await scheduler.restoreConfig(
                    localPath: file.filePath,
                    favorite: target,
                    deviceType: restoreDeviceType
                )
                await MainActor.run {
                    if result.exitCode == 0 {
                        statusMessage = restoreDeviceType == .fortigate
                            ? "Config restored to \(target.name). Device is rebooting."
                            : "Config restored to \(target.name)."
                    } else {
                        statusMessage = "Error: \(ConnectionTester.friendlyError(from: result.output, authMethod: target.authMethod))"
                    }
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
