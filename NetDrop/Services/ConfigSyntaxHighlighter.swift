import SwiftUI

struct ConfigSyntaxHighlighter {
    /// Highlight a FortiOS (or generic) config string into an AttributedString
    static func highlight(_ text: String) -> AttributedString {
        var result = AttributedString()

        let lines = text.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            result.append(highlightLine(line))
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }

        return result
    }

    private static func highlightLine(_ line: String) -> AttributedString {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Comment lines
        if trimmed.hasPrefix("#") {
            return styled(line, color: .gray)
        }

        // Empty lines
        if trimmed.isEmpty {
            return AttributedString(line)
        }

        // Build attributed string preserving leading whitespace
        let leadingSpaces = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
        var result = AttributedString(leadingSpaces)

        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
        let keyword = String(parts.first ?? "")
        let rest = parts.count > 1 ? String(parts[1]) : ""

        switch keyword.lowercased() {
        case "config":
            result.append(styled(keyword, color: .purple, bold: true))
            if !rest.isEmpty {
                result.append(styled(" ", color: .primary))
                result.append(styled(rest, color: .orange))
            }

        case "end", "next":
            result.append(styled(keyword, color: .purple, bold: true))

        case "edit":
            result.append(styled(keyword, color: .blue, bold: true))
            if !rest.isEmpty {
                result.append(styled(" ", color: .primary))
                result.append(highlightValue(rest))
            }

        case "set", "unset":
            result.append(styled(keyword, color: .blue))
            if !rest.isEmpty {
                // Split into variable name and value
                let setParts = rest.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: false)
                let varName = String(setParts.first ?? "")
                let value = setParts.count > 1 ? String(setParts[1]) : ""

                result.append(styled(" ", color: .primary))
                result.append(styled(varName, color: .cyan))
                if !value.isEmpty {
                    result.append(styled(" ", color: .primary))
                    result.append(highlightValue(value))
                }
            }

        case "append", "select", "rename", "move", "clone", "delete", "purge", "get", "show", "diagnose", "execute":
            result.append(styled(keyword, color: .blue))
            if !rest.isEmpty {
                result.append(styled(" ", color: .primary))
                result.append(highlightValue(rest))
            }

        default:
            result.append(highlightValue(trimmed))
        }

        return result
    }

    /// Highlight a value string — detects quoted strings, IPs, numbers, booleans
    private static func highlightValue(_ value: String) -> AttributedString {
        var result = AttributedString()
        var remaining = value[value.startIndex...]

        while !remaining.isEmpty {
            // Skip whitespace
            if remaining.first?.isWhitespace == true {
                let space = remaining.prefix(while: { $0.isWhitespace })
                result.append(AttributedString(String(space)))
                remaining = remaining[space.endIndex...]
                continue
            }

            // Quoted string
            if remaining.first == "\"" {
                if let endQuote = remaining.dropFirst().firstIndex(of: "\"") {
                    let quoted = remaining[remaining.startIndex...endQuote]
                    result.append(styled(String(quoted), color: .green))
                    remaining = remaining[remaining.index(after: endQuote)...]
                    continue
                }
            }

            // Token (non-whitespace)
            let token = remaining.prefix(while: { !$0.isWhitespace })
            let tokenStr = String(token)

            if isIPAddress(tokenStr) || isSubnetMask(tokenStr) || isCIDR(tokenStr) {
                result.append(styled(tokenStr, color: .yellow))
            } else if tokenStr == "enable" || tokenStr == "disable" {
                result.append(styled(tokenStr, color: .orange))
            } else if Int(tokenStr) != nil {
                result.append(styled(tokenStr, color: .mint))
            } else {
                result.append(styled(tokenStr, color: .primary))
            }

            remaining = remaining[token.endIndex...]
        }

        return result
    }

    private static func styled(_ text: String, color: Color, bold: Bool = false) -> AttributedString {
        var attr = AttributedString(text)
        attr.foregroundColor = color
        if bold {
            attr.font = .system(.body, design: .monospaced).bold()
        }
        return attr
    }

    private static func isIPAddress(_ s: String) -> Bool {
        let parts = s.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let n = Int(part) else { return false }
            return (0...255).contains(n)
        }
    }

    private static func isSubnetMask(_ s: String) -> Bool {
        isIPAddress(s) && (s.hasPrefix("255.") || s == "0.0.0.0")
    }

    private static func isCIDR(_ s: String) -> Bool {
        let parts = s.split(separator: "/")
        guard parts.count == 2 else { return false }
        guard isIPAddress(String(parts[0])) else { return false }
        guard let prefix = Int(parts[1]), (0...128).contains(prefix) else { return false }
        return true
    }
}
