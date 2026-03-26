import SwiftUI

struct BackupSchedulerView: View {
    @Environment(BackupScheduler.self) private var scheduler
    @Environment(FavoritesStore.self) private var favoritesStore

    @State private var showingAddJob = false
    @State private var editingJob: BackupJob?

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
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddJob) {
            BackupJobEditView(mode: .add)
        }
        .sheet(item: $editingJob) { job in
            BackupJobEditView(mode: .edit(job))
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
                Text("\(job.favorites.count) device(s) · every \(job.intervalMinutes) min")
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
    @State private var command = "show full-configuration"
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
                    TextField("Remote command", text: $command)
                        .font(.system(.body, design: .monospaced))
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
                command = job.remoteCommand
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
        job.remoteCommand = command
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
