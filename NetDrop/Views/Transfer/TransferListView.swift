import SwiftUI

struct TransferListView: View {
    @Environment(TransferManager.self) private var transferManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Transfers")
                    .font(.headline)
                Spacer()
                if transferManager.activeTasks.contains(where: { $0.status != .inProgress }) {
                    Button("Clear Completed") {
                        transferManager.clearCompleted()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if transferManager.activeTasks.isEmpty && transferManager.history.isEmpty {
                ContentUnavailableView(
                    "No Transfers",
                    systemImage: "arrow.up.arrow.down",
                    description: Text("Upload or download a file to see transfer activity.")
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    if !transferManager.activeTasks.isEmpty {
                        Section("Active") {
                            ForEach(transferManager.activeTasks) { task in
                                TransferTaskRow(task: task)
                            }
                        }
                    }

                    if !transferManager.history.isEmpty {
                        Section("Recent") {
                            ForEach(transferManager.history.prefix(20)) { record in
                                TransferRecordRow(record: record)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }
}

struct TransferTaskRow: View {
    @Environment(TransferManager.self) private var transferManager
    let task: TransferTask

    var body: some View {
        HStack {
            Image(systemName: task.direction == .upload ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(statusColor)

            VStack(alignment: .leading, spacing: 2) {
                Text((task.localPath as NSString).lastPathComponent)
                    .font(.body)
                Text("\(task.favorite.name) — \(task.remotePath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !task.progressText.isEmpty && task.status == .inProgress {
                    Text(task.progressText)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if let error = task.errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }

            Spacer()

            switch task.status {
            case .inProgress:
                ProgressView()
                    .controlSize(.small)
                Button {
                    transferManager.cancelTask(task)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            case .cancelled:
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch task.status {
        case .inProgress: .blue
        case .completed: .green
        case .failed: .red
        case .cancelled: .secondary
        }
    }
}

struct TransferRecordRow: View {
    let record: TransferRecord

    var body: some View {
        HStack {
            Image(systemName: record.direction == .upload ? "arrow.up.circle" : "arrow.down.circle")
                .foregroundStyle(record.status == .completed ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text((record.localPath as NSString).lastPathComponent)
                    .font(.body)
                Text("\(record.favoriteName) — \(record.remotePath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(record.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(record.status == .completed ? .green : .red)
                if let date = record.completedAt {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
