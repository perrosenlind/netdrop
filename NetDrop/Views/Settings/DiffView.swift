import SwiftUI

struct DiffView: View {
    let leftTitle: String
    let rightTitle: String
    let leftContent: String
    let rightContent: String

    @State private var diffLines: [DiffLine] = []
    @State private var showUnchanged = true

    private var filteredLines: [DiffLine] {
        showUnchanged ? diffLines : diffLines.filter { $0.type != .unchanged }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            HStack {
                Text("Diff")
                    .font(.headline)
                Spacer()

                let stats = DiffEngine.summary(of: diffLines)
                HStack(spacing: 12) {
                    Label("\(stats.added)", systemImage: "plus.circle")
                        .foregroundColor(.green)
                    Label("\(stats.removed)", systemImage: "minus.circle")
                        .foregroundColor(.red)
                    Label("\(stats.modified)", systemImage: "pencil.circle")
                        .foregroundColor(.orange)
                }
                .font(.caption)

                Toggle("Show unchanged", isOn: $showUnchanged)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
            }
            .padding()

            Divider()

            // Column headers
            HStack(spacing: 0) {
                Text(leftTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.bar)

                Divider().frame(height: 20)

                Text(rightTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.bar)
            }

            Divider()

            // Diff content
            if diffLines.isEmpty {
                ContentUnavailableView(
                    "Identical",
                    systemImage: "checkmark.circle",
                    description: Text("Both files are the same.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredLines) { line in
                            DiffLineRow(line: line)
                        }
                    }
                }
            }
        }
        .onAppear {
            diffLines = DiffEngine.diff(left: leftContent, right: rightContent)
        }
    }
}

struct DiffLineRow: View {
    let line: DiffLine

    var body: some View {
        HStack(spacing: 0) {
            // Left side
            HStack(spacing: 4) {
                Text(line.leftLineNumber.map { "\($0)" } ?? "")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 30, alignment: .trailing)

                Text(line.leftText ?? "")
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(leftBackground)

            Divider().frame(height: 18)

            // Right side
            HStack(spacing: 4) {
                Text(line.rightLineNumber.map { "\($0)" } ?? "")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 30, alignment: .trailing)

                Text(line.rightText ?? "")
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(rightBackground)
        }
    }

    private var leftBackground: Color {
        switch line.type {
        case .removed: .red.opacity(0.15)
        case .modified: .orange.opacity(0.1)
        default: .clear
        }
    }

    private var rightBackground: Color {
        switch line.type {
        case .added: .green.opacity(0.15)
        case .modified: .orange.opacity(0.1)
        default: .clear
        }
    }
}

/// Picker view for selecting two backups to compare
struct DiffPickerView: View {
    @Environment(BackupScheduler.self) private var scheduler
    @Environment(\.dismiss) private var dismiss

    @State private var leftPath: String?
    @State private var rightPath: String?
    @State private var showingDiff = false
    @State private var showingFilePicker = false
    @State private var pickerTarget: PickerTarget = .left

    enum PickerTarget { case left, right }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Compare Configs")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Divider()

            Form {
                Section("Left (older)") {
                    if let path = leftPath {
                        Text((path as NSString).lastPathComponent)
                            .font(.system(.body, design: .monospaced))
                    }
                    Button("Choose File…") {
                        pickerTarget = .left
                        showingFilePicker = true
                    }

                    if !scheduler.results.isEmpty {
                        Picker("Or pick a backup", selection: $leftPath) {
                            Text("—").tag(String?.none)
                            ForEach(scheduler.results.filter({ $0.status == .success })) { r in
                                Text("\(r.favoriteName) — \(r.timestamp.formatted())").tag(r.filePath)
                            }
                        }
                    }
                }

                Section("Right (newer)") {
                    if let path = rightPath {
                        Text((path as NSString).lastPathComponent)
                            .font(.system(.body, design: .monospaced))
                    }
                    Button("Choose File…") {
                        pickerTarget = .right
                        showingFilePicker = true
                    }

                    if !scheduler.results.isEmpty {
                        Picker("Or pick a backup", selection: $rightPath) {
                            Text("—").tag(String?.none)
                            ForEach(scheduler.results.filter({ $0.status == .success })) { r in
                                Text("\(r.favoriteName) — \(r.timestamp.formatted())").tag(r.filePath)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Compare") { showingDiff = true }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(leftPath == nil || rightPath == nil)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.text, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                switch pickerTarget {
                case .left: leftPath = url.path
                case .right: rightPath = url.path
                }
            }
        }
        .sheet(isPresented: $showingDiff) {
            if let lp = leftPath, let rp = rightPath,
               let leftContent = try? String(contentsOfFile: lp, encoding: .utf8),
               let rightContent = try? String(contentsOfFile: rp, encoding: .utf8) {
                DiffView(
                    leftTitle: (lp as NSString).lastPathComponent,
                    rightTitle: (rp as NSString).lastPathComponent,
                    leftContent: leftContent,
                    rightContent: rightContent
                )
                .frame(minWidth: 800, minHeight: 500)
            }
        }
    }
}
