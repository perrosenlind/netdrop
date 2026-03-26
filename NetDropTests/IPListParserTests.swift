import XCTest
@testable import NetDrop

final class IPListParserTests: XCTestCase {

    // MARK: - Basic parsing

    func testParsesSingleIP() {
        let result = IPListParser.parse("192.168.1.1")
        XCTAssertEqual(result, ["192.168.1.1"])
    }

    func testParsesMultipleIPs() {
        let input = """
        192.168.1.1
        192.168.1.2
        10.0.0.1
        """
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "192.168.1.2", "10.0.0.1"])
    }

    func testParsesHostnames() {
        let input = """
        fw-01.lab.local
        switch-core.prod
        """
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["fw-01.lab.local", "switch-core.prod"])
    }

    // MARK: - CSV format

    func testParsesCSVTakingFirstColumn() {
        let input = """
        192.168.1.1,FortiGate-01
        192.168.1.2,Core-Switch
        10.0.0.1,Lab-FW
        """
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "192.168.1.2", "10.0.0.1"])
    }

    func testParsesSemicolonDelimited() {
        let input = "192.168.1.1;FortiGate\n10.0.0.1;Switch"
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "10.0.0.1"])
    }

    func testParsesTabDelimited() {
        let input = "192.168.1.1\tFortiGate\n10.0.0.1\tSwitch"
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "10.0.0.1"])
    }

    func testParsesSpaceDelimited() {
        let input = "192.168.1.1 FortiGate\n10.0.0.1 Switch"
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "10.0.0.1"])
    }

    // MARK: - Comments and empty lines

    func testSkipsCommentLines() {
        let input = """
        # Device list
        192.168.1.1
        # This is a comment
        10.0.0.1
        """
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "10.0.0.1"])
    }

    func testSkipsEmptyLines() {
        let input = """
        192.168.1.1

        10.0.0.1

        """
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "10.0.0.1"])
    }

    func testSkipsWhitespaceOnlyLines() {
        let input = "192.168.1.1\n   \n10.0.0.1"
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "10.0.0.1"])
    }

    // MARK: - Deduplication

    func testDeduplicatesIPs() {
        let input = """
        192.168.1.1
        192.168.1.2
        192.168.1.1
        192.168.1.3
        192.168.1.2
        """
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "192.168.1.2", "192.168.1.3"])
    }

    // MARK: - Edge cases

    func testEmptyInput() {
        let result = IPListParser.parse("")
        XCTAssertEqual(result, [])
    }

    func testOnlyComments() {
        let input = """
        # comment 1
        # comment 2
        """
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, [])
    }

    func testTrimsWhitespace() {
        let input = "  192.168.1.1  \n  10.0.0.1  "
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "10.0.0.1"])
    }

    func testMixedFormats() {
        let input = """
        # Lab devices
        192.168.1.1,FGT-Lab-01
        192.168.1.2

        # Production
        10.0.0.1;Core-Switch
        10.0.0.2\tEdge-FW
        """
        let result = IPListParser.parse(input)
        XCTAssertEqual(result, ["192.168.1.1", "192.168.1.2", "10.0.0.1", "10.0.0.2"])
    }
}
