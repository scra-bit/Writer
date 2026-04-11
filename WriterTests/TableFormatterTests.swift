import XCTest
@testable import Writer

final class TableFormatterTests: XCTestCase {
    
    var formatter: TableFormatter!
    
    override func setUp() {
        super.setUp()
        formatter = TableFormatter()
    }
    
    override func tearDown() {
        formatter = nil
        super.tearDown()
    }
    
    // MARK: - Table Detection Tests
    
    func testDetectTableRanges_singleTable() {
        let text = """
        Some text before
        
        | Header 1 | Header 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        
        Some text after
        """
        
        let tables = formatter.detectTableRanges(in: text)
        
        XCTAssertEqual(tables.count, 1, "Should detect exactly one table")
        XCTAssertEqual(tables[0].lines.count, 3, "Table should have 3 lines: header, delimiter, and one data row")
    }
    
    func testDetectTableRanges_multipleTables() {
        let text = """
        | A | B |
        |---|---|
        | 1 | 2 |
        
        Some text
        
        | X | Y |
        |---|---|
        | 3 | 4 |
        """
        
        let tables = formatter.detectTableRanges(in: text)
        
        XCTAssertEqual(tables.count, 2, "Should detect exactly two tables")
    }
    
    func testDetectTableRanges_noTables() {
        let text = """
        This is just regular text.
        No tables here.
        
        Just some paragraphs.
        """
        
        let tables = formatter.detectTableRanges(in: text)
        
        XCTAssertEqual(tables.count, 0, "Should detect no tables in plain text")
    }
    
    func testDetectTableRanges_noDelimiterRow() {
        let text = """
        | Cell 1 | Cell 2 |
        | Cell 3 | Cell 4 |
        """
        
        let tables = formatter.detectTableRanges(in: text)
        
        XCTAssertEqual(tables.count, 0, "Should not detect table without delimiter row")
    }
    
    func testDetectTableRanges_incompleteTable() {
        let text = """
        | Header 1 | Header 2 |
        """
        
        let tables = formatter.detectTableRanges(in: text)
        
        XCTAssertEqual(tables.count, 0, "Should not detect incomplete table without delimiter row")
    }
    
    // MARK: - Table Row Parsing Tests
    
    func testParseTableRow_withPipes() {
        let row = "| Cell 1 | Cell 2 | Cell 3 |"
        
        let cells = formatter.parseTableRow(row)
        
        XCTAssertEqual(cells.count, 3, "Should parse 3 cells")
        XCTAssertEqual(cells[0], "Cell 1")
        XCTAssertEqual(cells[1], "Cell 2")
        XCTAssertEqual(cells[2], "Cell 3")
    }
    
    func testParseTableRow_withoutLeadingPipe() {
        let row = "Cell 1 | Cell 2 | Cell 3"
        
        let cells = formatter.parseTableRow(row)
        
        XCTAssertEqual(cells.count, 3, "Should parse 3 cells without leading pipe")
        XCTAssertEqual(cells[0], "Cell 1")
        XCTAssertEqual(cells[1], "Cell 2")
    }
    
    func testParseTableRow_withoutTrailingPipe() {
        let row = "| Cell 1 | Cell 2 | Cell 3"
        
        let cells = formatter.parseTableRow(row)
        
        XCTAssertEqual(cells.count, 3, "Should parse 3 cells without trailing pipe")
    }
    
    func testParseTableRow_noPipes() {
        let row = "Single Cell"
        
        let cells = formatter.parseTableRow(row)
        
        XCTAssertEqual(cells.count, 1, "Should parse single cell")
        XCTAssertEqual(cells[0], "Single Cell")
    }
    
    func testParseTableRow_emptyCells() {
        let row = "| | Cell | |"
        
        let cells = formatter.parseTableRow(row)
        
        XCTAssertEqual(cells.count, 4, "Should include empty cells")
        XCTAssertEqual(cells[0], "", "First cell should be empty")
        XCTAssertEqual(cells[1], "Cell")
        XCTAssertEqual(cells[2], "", "Third cell should be empty")
    }
    
    func testParseTableRow_whitespaceTrimming() {
        let row = "|  Cell 1  |   Cell 2   |"
        
        let cells = formatter.parseTableRow(row)
        
        XCTAssertEqual(cells[0], "Cell 1", "Should trim leading/trailing whitespace from cells")
        XCTAssertEqual(cells[1], "Cell 2")
    }
    
    // MARK: - Column Width Calculation Tests
    
    func testCalculateColumnWidths_basic() {
        let rows = [
            ["Header 1", "Header 2"],
            ["------", "------"],
            ["Short", "Longer Text"]
        ]
        
        let columns = formatter.calculateColumnWidths(rows: rows)
        
        XCTAssertEqual(columns.count, 2, "Should calculate 2 columns")
        XCTAssertEqual(columns[0].width, max(7, 3), "First column width should account for longest content")
        XCTAssertEqual(columns[1].width, 11, "Second column width should be at least length of 'Longer Text'")
    }
    
    func testCalculateColumnWidths_alignmentParsing() {
        let rows = [
            ["Left", "Center", "Right", "None"],
            [":---", ":---:", "---:", "----"],
            ["a", "b", "c", "d"]
        ]
        
        let columns = formatter.calculateColumnWidths(rows: rows)
        
        XCTAssertEqual(columns.count, 4)
        XCTAssertEqual(columns[0].alignment, .left, "Should parse left alignment from :---")
        XCTAssertEqual(columns[1].alignment, .center, "Should parse center alignment from :---:")
        XCTAssertEqual(columns[2].alignment, .right, "Should parse right alignment from ---:")
        XCTAssertEqual(columns[3].alignment, .none, "Should parse none alignment from ----")
    }
    
    func testCalculateColumnWidths_cjkCharacters() {
        let rows = [
            ["名前", "説明"],
            ["----", "------"],
            ["田中", "これはテストです"]
        ]
        
        let columns = formatter.calculateColumnWidths(rows: rows)
        
        XCTAssertEqual(columns.count, 2, "Should calculate 2 columns")
        // CJK characters should count as 2 width each
        XCTAssertEqual(columns[0].width, max(6, 3), "名前 is 2 chars but 4 visual width")
        XCTAssertEqual(columns[1].width, max(12, 3), "これはテストです is 6 chars but 12 visual width")
    }
    
    func testCalculateColumnWidths_minimumWidth() {
        let rows = [
            ["H", "I"],
            ["-", "-"]
        ]
        
        let columns = formatter.calculateColumnWidths(rows: rows)
        
        XCTAssertEqual(columns[0].width, 3, "Column width should be at least 3")
        XCTAssertEqual(columns[1].width, 3, "Column width should be at least 3")
    }
    
    func testCalculateColumnWidths_insufficientRows() {
        let rows = [
            ["Header 1", "Header 2"]
        ]
        
        let columns = formatter.calculateColumnWidths(rows: rows)
        
        XCTAssertEqual(columns.count, 0, "Should return empty for fewer than 2 rows")
    }
    
    // MARK: - Cell Formatting Tests
    
    func testFormatCell_leftAlignment() {
        let result = formatter.formatCell("Text", width: 10, alignment: .left)
        
        XCTAssertEqual(result, "Text      ", "Should pad on right for left alignment")
    }
    
    func testFormatCell_rightAlignment() {
        let result = formatter.formatCell("Text", width: 10, alignment: .right)
        
        XCTAssertEqual(result, "      Text", "Should pad on left for right alignment")
    }
    
    func testFormatCell_centerAlignment() {
        let result = formatter.formatCell("Text", width: 10, alignment: .center)
        
        XCTAssertEqual(result, "   Text   ", "Should pad equally on both sides for center alignment")
    }
    
    func testFormatCell_noneAlignment() {
        let result = formatter.formatCell("Text", width: 10, alignment: .none)
        
        XCTAssertEqual(result, "Text      ", "Should default to left alignment for .none")
    }
    
    func testFormatCell_textLongerThanWidth() {
        let result = formatter.formatCell("This is a very long text", width: 10, alignment: .left)
        
        XCTAssertEqual(result, "This is a very long text", "Should not truncate text longer than width")
    }
    
    func testFormatCell_evenPaddingCenter() {
        // 10 width - 4 text = 6 padding, split 3 and 3
        let result = formatter.formatCell("Test", width: 10, alignment: .center)
        
        XCTAssertEqual(result, "   Test   ")
    }
    
    func testFormatCell_oddPaddingCenter() {
        // 9 width - 4 text = 5 padding, split 2 and 3
        let result = formatter.formatCell("Test", width: 9, alignment: .center)
        
        XCTAssertEqual(result, "  Test   ")
    }
    
    // MARK: - Full Table Formatting Tests
    
    func testFormatTable_basic() {
        let lines = [
            "| Name | Age |",
            "|------|-----|",
            "| Alice | 30 |"
        ]
        
        let result = formatter.formatTable(lines)
        
        let expectedLines = result.components(separatedBy: "\n")
        XCTAssertEqual(expectedLines.count, 3, "Should produce 3 lines")
        
        // Check that cells are properly aligned
        XCTAssertTrue(expectedLines[0].hasPrefix("|"), "First line should start with pipe")
        XCTAssertTrue(expectedLines[2].hasPrefix("|"), "Third line should start with pipe")
    }
    
    func testFormatTable_withDelimiterRow() {
        let lines = [
            "| Left | Center | Right |",
            "|:----|:------:|------:|",
            "| A | B | C |"
        ]
        
        let result = formatter.formatTable(lines)
        
        let lines = result.components(separatedBy: "\n")
        
        // Delimiter row should be reformatted
        XCTAssertTrue(lines[1].contains(":"), "Delimiter row should contain alignment markers")
    }
    
    func testFormatTable_multipleRows() {
        let lines = [
            "| Col1 | Col2 |",
            "|------|------|",
            "| A    | B    |",
            "| C    | D    |",
            "| E    | F    |"
        ]
        
        let result = formatter.formatTable(lines)
        
        let resultLines = result.components(separatedBy: "\n")
        XCTAssertEqual(resultLines.count, 5, "Should preserve all rows")
    }
    
    func testFormatTable_insufficientRows() {
        let lines = [
            "| Col1 | Col2 |"
        ]
        
        let result = formatter.formatTable(lines)
        
        XCTAssertEqual(result, "| Col1 | Col2 |", "Should return original for single row")
    }
    
    // MARK: - Document Formatting Tests
    
    func testFormatEntireDocument_singleTable() {
        let text = """
        Before the table:
        
        | Name | Role |
        |------|------|
        | John | Dev  |
        
        After the table.
        """
        
        let result = formatter.formatEntireDocument(text)
        
        // Should have reformatted the table
        XCTAssertNotEqual(result, text, "Document should be modified when table exists")
        XCTAssertTrue(result.contains("| Name | Role |"), "Should preserve header content")
    }
    
    func testFormatEntireDocument_multipleTables() {
        let text = """
        | A | B |
        |---|---|
        | 1 | 2 |
        
        Some text in between.
        
        | X | Y |
        |---|---|
        | 3 | 4 |
        """
        
        let result = formatter.formatEntireDocument(text)
        
        // Both tables should be formatted
        let tables = formatter.detectTableRanges(in: result)
        XCTAssertEqual(tables.count, 2, "Should still detect 2 tables after formatting")
    }
    
    func testFormatEntireDocument_nonTablePreservation() {
        let text = """
        This is a paragraph.
        
        | Table | Here |
        |-------|------|
        | Data  | More |
        
        Another paragraph.
        
        More text without tables.
        """
        
        let result = formatter.formatEntireDocument(text)
        
        XCTAssertTrue(result.contains("This is a paragraph."), "Should preserve non-table text")
        XCTAssertTrue(result.contains("Another paragraph."), "Should preserve text after table")
        XCTAssertTrue(result.contains("More text without tables."), "Should preserve final paragraph")
    }
    
    // MARK: - Edge Cases Tests
    
    func testDetectTableRanges_emptyInput() {
        let text = ""
        
        let tables = formatter.detectTableRanges(in: text)
        
        XCTAssertEqual(tables.count, 0, "Should return empty for empty input")
    }
    
    func testFormatEntireDocument_emptyInput() {
        let text = ""
        
        let result = formatter.formatEntireDocument(text)
        
        XCTAssertEqual(result, "", "Should return empty string for empty input")
    }
    
    func testParseTableRow_emptyRow() {
        let row = ""
        
        let cells = formatter.parseTableRow(row)
        
        XCTAssertEqual(cells.count, 1, "Empty row should produce one empty cell")
        XCTAssertEqual(cells[0], "", "Cell should be empty")
    }
    
    func testFormatTable_onlyDelimiterRow() {
        let lines = [
            "|------|------|"
        ]
        
        let result = formatter.formatTable(lines)
        
        XCTAssertEqual(result, lines[0], "Should return original for single delimiter row")
    }
    
    func testCalculateColumnWidths_emptyRows() {
        let rows: [[String]] = []
        
        let columns = formatter.calculateColumnWidths(rows: rows)
        
        XCTAssertEqual(columns.count, 0, "Should return empty for empty rows")
    }
    
    func testFormatCell_emptyContent() {
        let result = formatter.formatCell("", width: 5, alignment: .left)
        
        XCTAssertEqual(result, "     ", "Empty content should be padded to width")
    }
    
    // MARK: - ColumnAlignment Enum Tests
    
    func testColumnAlignment_equality() {
        XCTAssertEqual(TableFormatter.ColumnAlignment.left, .left, "Left should equal left")
        XCTAssertEqual(TableFormatter.ColumnAlignment.center, .center, "Center should equal center")
        XCTAssertEqual(TableFormatter.ColumnAlignment.right, .right, "Right should equal right")
        XCTAssertEqual(TableFormatter.ColumnAlignment.none, .none, "None should equal none")
    }
    
    func testColumnAlignment_inequality() {
        XCTAssertNotEqual(TableFormatter.ColumnAlignment.left, .right, "Left should not equal right")
        XCTAssertNotEqual(TableFormatter.ColumnAlignment.center, .left, "Center should not equal left")
    }
    
    // MARK: - TableColumn Struct Tests
    
    func testTableColumn_equality() {
        let col1 = TableFormatter.TableColumn(width: 10, alignment: .left)
        let col2 = TableFormatter.TableColumn(width: 10, alignment: .left)
        let col3 = TableFormatter.TableColumn(width: 5, alignment: .left)
        
        XCTAssertEqual(col1, col2, "Columns with same width and alignment should be equal")
        XCTAssertNotEqual(col1, col3, "Columns with different width should not be equal")
    }
}