import XCTest
@testable import NetDrop

final class DiffEngineTests: XCTestCase {

    func testIdenticalFiles() {
        let text = "line1\nline2\nline3"
        let result = DiffEngine.diff(left: text, right: text)
        XCTAssertTrue(result.allSatisfy { $0.type == .unchanged })
        XCTAssertEqual(result.count, 3)
    }

    func testAddedLines() {
        let left = "line1\nline3"
        let right = "line1\nline2\nline3"
        let result = DiffEngine.diff(left: left, right: right)

        let added = result.filter { $0.type == .added }
        XCTAssertEqual(added.count, 1)
        XCTAssertEqual(added.first?.rightText, "line2")
    }

    func testRemovedLines() {
        let left = "line1\nline2\nline3"
        let right = "line1\nline3"
        let result = DiffEngine.diff(left: left, right: right)

        let removed = result.filter { $0.type == .removed }
        XCTAssertEqual(removed.count, 1)
        XCTAssertEqual(removed.first?.leftText, "line2")
    }

    func testModifiedLines() {
        let left = "line1\nold value\nline3"
        let right = "line1\nnew value\nline3"
        let result = DiffEngine.diff(left: left, right: right)

        let modified = result.filter { $0.type == .modified }
        XCTAssertEqual(modified.count, 1)
        XCTAssertEqual(modified.first?.leftText, "old value")
        XCTAssertEqual(modified.first?.rightText, "new value")
    }

    func testEmptyLeft() {
        let result = DiffEngine.diff(left: "", right: "line1\nline2")
        let added = result.filter { $0.type == .added }
        XCTAssertGreaterThanOrEqual(added.count, 1)
    }

    func testEmptyRight() {
        let result = DiffEngine.diff(left: "line1\nline2", right: "")
        let removed = result.filter { $0.type == .removed }
        XCTAssertGreaterThanOrEqual(removed.count, 1)
    }

    func testBothEmpty() {
        let result = DiffEngine.diff(left: "", right: "")
        XCTAssertTrue(result.allSatisfy { $0.type == .unchanged })
    }

    func testSummary() {
        let left = "a\nb\nc\nd"
        let right = "a\nB\nc\ne"
        let result = DiffEngine.diff(left: left, right: right)
        let stats = DiffEngine.summary(of: result)

        // a=unchanged, b->B=modified, c=unchanged, d removed / e added
        XCTAssertEqual(stats.unchanged, 2)
        XCTAssertGreaterThanOrEqual(stats.added + stats.removed + stats.modified, 2)
    }

    func testLargeConfigDiff() {
        // Simulate a config file change
        var left = (1...100).map { "config line \($0)" }.joined(separator: "\n")
        var right = left
        // Change line 50
        right = right.replacingOccurrences(of: "config line 50", with: "config line 50 CHANGED")
        // Add a line
        right += "\nconfig line 101"

        let result = DiffEngine.diff(left: left, right: right)
        let stats = DiffEngine.summary(of: result)

        XCTAssertGreaterThan(stats.unchanged, 90)
        XCTAssertGreaterThanOrEqual(stats.added + stats.modified, 1)
    }
}
