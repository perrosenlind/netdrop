import Foundation

struct IPListParser {
    /// Parse a text file content into a list of IP addresses / hostnames.
    /// Supports: one per line, CSV, semicolon/tab/space delimited, # comments.
    static func parse(_ content: String) -> [String] {
        var addresses: [String] = []
        let seen = NSMutableSet()

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            let address = trimmed
                .components(separatedBy: CharacterSet(charactersIn: ",;\t "))
                .first?
                .trimmingCharacters(in: .whitespaces) ?? ""

            guard !address.isEmpty, !seen.contains(address) else { continue }

            seen.add(address)
            addresses.append(address)
        }

        return addresses
    }
}
