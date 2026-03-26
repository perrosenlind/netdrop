import XCTest
@testable import NetDrop

final class RemoteFileEntryTests: XCTestCase {

    func testDirectoryIcon() {
        let entry = RemoteFileEntry(name: "firmware", path: "/firmware", isDirectory: true, isSymlink: false, size: 0, permissions: "drwxr-xr-x")
        XCTAssertEqual(entry.icon, "folder.fill")
    }

    func testSymlinkIcon() {
        let entry = RemoteFileEntry(name: "link", path: "/link", isDirectory: false, isSymlink: true, size: 0, permissions: "lrwxr-xr-x")
        XCTAssertEqual(entry.icon, "arrow.triangle.turn.up.right.diamond")
    }

    func testConfigFileIcon() {
        for ext in ["conf", "cfg", "ini", "yaml", "yml", "json", "xml"] {
            let entry = RemoteFileEntry(name: "file.\(ext)", path: "/file.\(ext)", isDirectory: false, isSymlink: false, size: 100, permissions: "-rw-r--r--")
            XCTAssertEqual(entry.icon, "doc.text", "Expected doc.text for .\(ext)")
        }
    }

    func testLogFileIcon() {
        for ext in ["log", "txt"] {
            let entry = RemoteFileEntry(name: "file.\(ext)", path: "/file.\(ext)", isDirectory: false, isSymlink: false, size: 100, permissions: "-rw-r--r--")
            XCTAssertEqual(entry.icon, "doc.plaintext")
        }
    }

    func testBinaryFileIcon() {
        for ext in ["bin", "img", "iso", "out"] {
            let entry = RemoteFileEntry(name: "file.\(ext)", path: "/file.\(ext)", isDirectory: false, isSymlink: false, size: 100, permissions: "-rw-r--r--")
            XCTAssertEqual(entry.icon, "externaldrive")
        }
    }

    func testScriptFileIcon() {
        for ext in ["sh", "py", "pl"] {
            let entry = RemoteFileEntry(name: "file.\(ext)", path: "/file.\(ext)", isDirectory: false, isSymlink: false, size: 100, permissions: "-rwxr-xr-x")
            XCTAssertEqual(entry.icon, "terminal")
        }
    }

    func testUnknownFileIcon() {
        let entry = RemoteFileEntry(name: "file.xyz", path: "/file.xyz", isDirectory: false, isSymlink: false, size: 100, permissions: "-rw-r--r--")
        XCTAssertEqual(entry.icon, "doc")
    }

    func testFormattedSizeForDirectory() {
        let entry = RemoteFileEntry(name: "dir", path: "/dir", isDirectory: true, isSymlink: false, size: 4096, permissions: "drwxr-xr-x")
        XCTAssertEqual(entry.formattedSize, "—")
    }

    func testFormattedSizeForFile() {
        let entry = RemoteFileEntry(name: "file.bin", path: "/file.bin", isDirectory: false, isSymlink: false, size: 1048576, permissions: "-rw-r--r--")
        // Should be something like "1 MB" — just verify it's not empty or "—"
        XCTAssertNotEqual(entry.formattedSize, "—")
        XCTAssertFalse(entry.formattedSize.isEmpty)
    }
}
