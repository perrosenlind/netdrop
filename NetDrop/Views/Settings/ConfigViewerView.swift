import SwiftUI
import AppKit

// MARK: - NSTextView wrapper for fast syntax-highlighted config rendering

struct HighlightedTextView: NSViewRepresentable {
    let attributedString: NSAttributedString

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.textContainerInset = NSSize(width: 12, height: 8)
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        // Enable line wrapping
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        textView.textStorage?.setAttributedString(attributedString)
    }
}

// MARK: - Config Viewer

struct ConfigViewerView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let content: String

    @State private var highlighted: NSAttributedString?

    private var lineCount: Int {
        content.components(separatedBy: "\n").count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()

                Text("\(lineCount) lines")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Text("Cmd+F to search")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

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

            // Config content
            if let highlighted {
                HighlightedTextView(attributedString: highlighted)
            } else {
                ProgressView("Highlighting…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .task {
            let text = content
            let result = await Task.detached(priority: .userInitiated) {
                ConfigSyntaxHighlighter.highlight(text)
            }.value
            highlighted = result
        }
    }
}
