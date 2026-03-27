import SwiftUI

struct BackupFileDetailView: View {
    let file: BackupFileItem
    let onRestore: () -> Void
    let onRefresh: () -> Void

    @State private var highlighted: NSAttributedString?
    @State private var content: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.deviceName)
                        .font(.headline)
                    Text("\(file.formattedDate) · \(file.formattedSize)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Cmd+F to search")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Button {
                    NSWorkspace.shared.selectFile(file.filePath, inFileViewerRootedAtPath: "")
                } label: {
                    Label("Finder", systemImage: "folder")
                }
                .controlSize(.small)

                Button {
                    onRestore()
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }
                .controlSize(.small)
            }
            .padding()

            Divider()

            // Config content
            if let highlighted {
                HighlightedTextView(attributedString: highlighted)
            } else {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task(id: file.id) {
            await loadAndHighlight()
        }
    }

    private func loadAndHighlight() async {
        let path = file.filePath
        let text = (try? String(contentsOfFile: path, encoding: .utf8)) ?? "Could not read file"
        content = text

        let result = await Task.detached(priority: .userInitiated) {
            ConfigSyntaxHighlighter.highlight(text)
        }.value
        highlighted = result
    }
}
