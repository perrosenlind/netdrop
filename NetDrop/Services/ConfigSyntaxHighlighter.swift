import AppKit

struct ConfigSyntaxHighlighter {
    /// Highlight a FortiOS config into an NSAttributedString for use with NSTextView
    static func highlight(_ text: String, fontSize: CGFloat = 13) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let mono = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let monoBold = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: mono,
            .foregroundColor: NSColor.textColor
        ]

        let lines = text.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            result.append(highlightLine(line, mono: mono, monoBold: monoBold, defaultAttrs: defaultAttrs))
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n", attributes: defaultAttrs))
            }
        }

        return result
    }

    private static func highlightLine(
        _ line: String,
        mono: NSFont,
        monoBold: NSFont,
        defaultAttrs: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix("#") {
            return NSAttributedString(string: line, attributes: attrs(mono, .gray))
        }

        if trimmed.isEmpty {
            return NSAttributedString(string: line, attributes: defaultAttrs)
        }

        let result = NSMutableAttributedString()
        let leading = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
        result.append(NSAttributedString(string: leading, attributes: defaultAttrs))

        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
        let keyword = String(parts.first ?? "")
        let rest = parts.count > 1 ? String(parts[1]) : ""

        switch keyword.lowercased() {
        case "config":
            result.append(NSAttributedString(string: keyword, attributes: attrs(monoBold, .systemPurple)))
            if !rest.isEmpty {
                result.append(NSAttributedString(string: " ", attributes: defaultAttrs))
                result.append(NSAttributedString(string: rest, attributes: attrs(mono, .systemOrange)))
            }

        case "end", "next":
            result.append(NSAttributedString(string: keyword, attributes: attrs(monoBold, .systemPurple)))

        case "edit":
            result.append(NSAttributedString(string: keyword, attributes: attrs(monoBold, .systemBlue)))
            if !rest.isEmpty {
                result.append(NSAttributedString(string: " ", attributes: defaultAttrs))
                result.append(highlightValue(rest, mono: mono, defaultAttrs: defaultAttrs))
            }

        case "set", "unset":
            result.append(NSAttributedString(string: keyword, attributes: attrs(mono, .systemBlue)))
            if !rest.isEmpty {
                let setParts = rest.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
                let varName = String(setParts.first ?? "")
                let value = setParts.count > 1 ? String(setParts[1]) : ""

                result.append(NSAttributedString(string: " ", attributes: defaultAttrs))
                result.append(NSAttributedString(string: varName, attributes: attrs(mono, .systemCyan)))
                if !value.isEmpty {
                    result.append(NSAttributedString(string: " ", attributes: defaultAttrs))
                    result.append(highlightValue(value, mono: mono, defaultAttrs: defaultAttrs))
                }
            }

        case "append", "select", "rename", "move", "clone", "delete", "purge", "get", "show", "diagnose", "execute":
            result.append(NSAttributedString(string: keyword, attributes: attrs(mono, .systemBlue)))
            if !rest.isEmpty {
                result.append(NSAttributedString(string: " ", attributes: defaultAttrs))
                result.append(highlightValue(rest, mono: mono, defaultAttrs: defaultAttrs))
            }

        default:
            result.append(highlightValue(trimmed, mono: mono, defaultAttrs: defaultAttrs))
        }

        return result
    }

    private static func highlightValue(
        _ value: String,
        mono: NSFont,
        defaultAttrs: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var remaining = value[value.startIndex...]

        while !remaining.isEmpty {
            if remaining.first?.isWhitespace == true {
                let space = remaining.prefix(while: { $0.isWhitespace })
                result.append(NSAttributedString(string: String(space), attributes: defaultAttrs))
                remaining = remaining[space.endIndex...]
                continue
            }

            if remaining.first == "\"" {
                if let endQuote = remaining.dropFirst().firstIndex(of: "\"") {
                    let quoted = remaining[remaining.startIndex...endQuote]
                    result.append(NSAttributedString(string: String(quoted), attributes: attrs(mono, .systemGreen)))
                    remaining = remaining[remaining.index(after: endQuote)...]
                    continue
                }
            }

            let token = remaining.prefix(while: { !$0.isWhitespace })
            let tokenStr = String(token)

            if isIPAddress(tokenStr) || isCIDR(tokenStr) {
                result.append(NSAttributedString(string: tokenStr, attributes: attrs(mono, .systemYellow)))
            } else if tokenStr == "enable" || tokenStr == "disable" {
                result.append(NSAttributedString(string: tokenStr, attributes: attrs(mono, .systemOrange)))
            } else if Int(tokenStr) != nil {
                result.append(NSAttributedString(string: tokenStr, attributes: attrs(mono, .systemMint)))
            } else {
                result.append(NSAttributedString(string: tokenStr, attributes: defaultAttrs))
            }

            remaining = remaining[token.endIndex...]
        }

        return result
    }

    private static func attrs(_ font: NSFont, _ color: NSColor) -> [NSAttributedString.Key: Any] {
        [.font: font, .foregroundColor: color]
    }

    private static func isIPAddress(_ s: String) -> Bool {
        let parts = s.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { Int($0) != nil && (0...255).contains(Int($0)!) }
    }

    private static func isCIDR(_ s: String) -> Bool {
        let parts = s.split(separator: "/")
        guard parts.count == 2, isIPAddress(String(parts[0])) else { return false }
        guard let prefix = Int(parts[1]), (0...128).contains(prefix) else { return false }
        return true
    }
}
