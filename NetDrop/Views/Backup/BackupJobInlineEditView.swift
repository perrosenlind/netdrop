import SwiftUI

struct BackupJobInlineEditView: View {
    @Environment(BackupScheduler.self) private var scheduler
    @Environment(FavoritesStore.self) private var favoritesStore

    let mode: BackupJobEditMode
    let onDone: () -> Void

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
            HStack {
                Text(isEditing ? "Edit Job" : "New Backup Job")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

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
                        Text("Downloads sys_config via SCP with legacy protocol (-O)")
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(fav.name).fontWeight(.medium)
                                Text("\(fav.username)@\(fav.host)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
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

            Divider()

            HStack {
                Button("Cancel") { onDone() }
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
        onDone()
    }
}
