import SwiftUI

struct ConfigViewerView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let content: String

    @State private var highlighted: AttributedString?
    @State private var searchText = ""
    @State private var showLineNumbers = true

    private var lines: [String] {
        content.components(separatedBy: "\n")
    }

    private var filteredLineIndices: [Int] {
        if searchText.isEmpty {
            return Array(0..<lines.count)
        }
        return lines.indices.filter { lines[$0].localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                Spacer()

                Text("\(lines.count) lines")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Toggle("Lines", isOn: $showLineNumbers)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)

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

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search config...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Text("\(filteredLineIndices.count) matches")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            // Config content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(filteredLineIndices, id: \.self) { index in
                        HStack(alignment: .top, spacing: 0) {
                            if showLineNumbers {
                                Text("\(index + 1)")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 40, alignment: .trailing)
                                    .padding(.trailing, 8)

                                Divider()
                                    .frame(height: 16)
                                    .padding(.trailing, 8)
                            }

                            if let highlighted {
                                // Use highlighted version - extract the line
                                Text(highlightedLine(index))
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            } else {
                                Text(lines[index])
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, showLineNumbers ? 4 : 12)
                        .padding(.vertical, 1)
                        .background(
                            !searchText.isEmpty && lines[index].localizedCaseInsensitiveContains(searchText)
                                ? Color.yellow.opacity(0.1)
                                : Color.clear
                        )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .task {
            // Highlight in background
            let text = content
            let result = await Task.detached {
                ConfigSyntaxHighlighter.highlight(text)
            }.value
            highlighted = result
        }
    }

    /// Get highlighted attributed string for a single line
    private func highlightedLine(_ index: Int) -> AttributedString {
        ConfigSyntaxHighlighter.highlight(lines[index])
    }
}
