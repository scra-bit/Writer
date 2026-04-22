import XCTest
@testable import Writer

final class TableFormatterTests: XCTestCase {
    private let formatter = TableFormatter()

    func testDetectTableRangesFindsOnlyValidTables() {
        let text = """
        Intro

        | Name | Score |
        | ---- | ----: |
        | Ana  |  10   |

        Not a table
        value | still not one
        """

        let tables = formatter.detectTableRanges(in: text)

        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables[0].lines.count, 3)
        XCTAssertEqual(tables[0].lines[0], "| Name | Score |")
    }

    func testParseTableRowHandlesOptionalEdgePipes() {
        XCTAssertEqual(formatter.parseTableRow("| one | two |"), ["one", "two"])
        XCTAssertEqual(formatter.parseTableRow("one | two"), ["one", "two"])
    }

    func testCalculateColumnWidthsRespectsAlignmentAndWideCharacters() {
        let columns = formatter.calculateColumnWidths(rows: [
            ["Name", "Value"],
            [":---", "---:"],
            ["猫", "1000"]
        ])

        XCTAssertEqual(columns.count, 2)
        XCTAssertEqual(columns[0].alignment, .left)
        XCTAssertEqual(columns[1].alignment, .right)
        XCTAssertEqual(columns[0].width, 4)
        XCTAssertEqual(columns[1].width, 5)
    }

    func testFormatEntireDocumentFormatsTablesAndPreservesOtherText() {
        let text = """
        Before

        | Name|Value|
        |:--|--:|
        | a |1|

        After
        """

        let formatted = formatter.formatEntireDocument(text)

        XCTAssertTrue(formatted.contains("Before"))
        XCTAssertTrue(formatted.contains("After"))
        XCTAssertTrue(formatted.contains("| Name | Value |"))
        XCTAssertTrue(formatted.contains("| :--- | ----: |"))
        XCTAssertTrue(formatted.contains("| a    |     1 |"))
    }
}
