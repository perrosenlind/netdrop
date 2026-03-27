import SwiftUI
import AppKit

// MARK: - NSTextView wrapper for fast syntax-highlighted config rendering

struct HighlightedTextView: NSViewRepresentable {
    let attributedString: NSAttributedString
    let searchText: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 12, height: 8)
        textView.backgroundColor = .textBackgroundColor
        textView.drawsBackground = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false

        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView

        // Apply highlighted text with search highlights
        let display = NSMutableAttributedString(attributedString: attributedString)

        if !searchText.isEmpty {
            let fullText = display.string
            let searchLower = searchText.lowercased()
            let fullLower = fullText.lowercased()
            var searchStart = fullLower.startIndex

            while let range = fullLower.range(of: searchLower, range: searchStart..<fullLower.endIndex) {
                let nsRange = NSRange(range, in: fullText)
                display.addAttribute(.backgroundColor, value: NSColor.systemYellow.withAlphaComponent(0.4), range: nsRange)
                searchStart = range.upperBound
            }
        }

        textView.textStorage?.setAttributedString(display)

        // Scroll to first match
        if !searchText.isEmpty {
            let fullText = display.string.lowercased()
            if let range = fullText.range(of: searchText.lowercased()) {
                let nsRange = NSRange(range, in: display.string)
                textView.scrollRangeToVisible(nsRange)
            }
        }
    }
}

// MARK: - Search bar component

struct ConfigSearchBar: View {
    @Binding var text: String
    let matchCount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField("Search config…", text: $text)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .default))
            if !text.isEmpty {
                Text("\(matchCount) matches")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.bar)
    }
}

// MARK: - Config Viewer (sheet version)

struct ConfigViewerView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let content: String

    @State private var highlighted: NSAttributedString?
    @State private var searchText = ""

    private var lineCount: Int {
        content.components(separatedBy: "\n").count
    }

    private var matchCount: Int {
        guard !searchText.isEmpty else { return 0 }
        return content.lowercased().components(separatedBy: searchText.lowercased()).count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
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

            ConfigSearchBar(text: $searchText, matchCount: matchCount)

            Divider()

            if let highlighted {
                HighlightedTextView(attributedString: highlighted, searchText: searchText)
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
