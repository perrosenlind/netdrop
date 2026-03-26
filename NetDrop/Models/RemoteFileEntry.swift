import Foundation

struct RemoteFileEntry: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let isSymlink: Bool
    let size: Int64
    let permissions: String

    var icon: String {
        if isDirectory { return "folder.fill" }
        if isSymlink { return "arrow.triangle.turn.up.right.diamond" }

        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "conf", "cfg", "ini", "yaml", "yml", "json", "xml":
            return "doc.text"
        case "log", "txt":
            return "doc.plaintext"
        case "bin", "img", "iso", "out":
            return "externaldrive"
        case "sh", "py", "pl":
            return "terminal"
        default:
            return "doc"
        }
    }

    var formattedSize: String {
        if isDirectory { return "—" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
