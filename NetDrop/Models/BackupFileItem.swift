import Foundation

struct BackupFileItem: Identifiable, Hashable {
    let id: String  // file path
    let deviceName: String
    let timestamp: Date?
    let filePath: String
    let fileSize: Int64
    let fileName: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedDate: String {
        if let timestamp {
            return timestamp.formatted(date: .abbreviated, time: .shortened)
        }
        return "Unknown date"
    }

    /// Parse a backup filename like "DeviceName_2026-03-27T14-30-45Z.conf"
    static func parse(url: URL) -> BackupFileItem? {
        let fileName = url.lastPathComponent
        guard fileName.hasSuffix(".conf") || fileName.hasSuffix(".txt") else { return nil }

        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attrs?[.size] as? Int64) ?? 0

        // Try to extract device name and timestamp from filename
        let baseName = (fileName as NSString).deletingPathExtension
        let parts = baseName.split(separator: "_", maxSplits: 1)

        let deviceName: String
        let timestamp: Date?

        if parts.count == 2 {
            deviceName = String(parts[0])
            // Try parsing ISO8601 with dashes replacing colons
            let dateStr = String(parts[1]).replacingOccurrences(of: "-", with: ":")
                .replacingOccurrences(of: "T:", with: "T")  // Fix T: back to T
            let formatter = ISO8601DateFormatter()
            timestamp = formatter.date(from: dateStr)
                ?? (attrs?[.modificationDate] as? Date)
        } else {
            deviceName = baseName
            timestamp = attrs?[.modificationDate] as? Date
        }

        return BackupFileItem(
            id: url.path,
            deviceName: deviceName,
            timestamp: timestamp,
            filePath: url.path,
            fileSize: size,
            fileName: fileName
        )
    }
}
