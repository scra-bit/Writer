import Foundation

// MARK: - Table Formatter

/// Handles formatting and detection of markdown tables in text documents.
struct TableFormatter {

    // MARK: - Types

    /// Alignment options for table columns.
    enum ColumnAlignment: Equatable {
        case left
        case center
        case right
        case none
    }

    /// Represents a table column with its width and alignment.
    struct TableColumn {
        let width: Int
        let alignment: ColumnAlignment

        static func == (lhs: TableColumn, rhs: TableColumn) -> Bool {
            lhs.width == rhs.width && lhs.alignment == rhs.alignment
        }
    }

    // MARK: - Table Detection

    /// Detects all table ranges within the given text.
    /// - Parameter text: The document text to scan for tables.
    /// - Returns: An array of tuples containing the range and lines for each detected table.
    func detectTableRanges(in text: String) -> [(range: Range<String.Index>, lines: [String])] {
        let lines = text.components(separatedBy: .newlines)
        var tables: [(range: Range<String.Index>, lines: [String])] = []

        var i = 0
        while i < lines.count {
            guard isTableRow(lines[i]) else {
                i += 1
                continue
            }

            // Found potential table start - look for delimiter row
            guard i + 1 < lines.count else {
                i += 1
                continue
            }

            guard isDelimiterRow(lines[i + 1]) else {
                i += 1
                continue
            }

            // Found delimiter - collect all table rows
            var tableLines: [String] = [lines[i], lines[i + 1]]
            var startIndex = i
            i += 2

            // Continue collecting table rows until we hit a non-table row
            while i < lines.count && isTableRow(lines[i]) {
                tableLines.append(lines[i])
                i += 1
            }

            // Calculate the range in the original text
            let startCharIndex = lines[0..<startIndex].joined(separator: "\n").count + (startIndex > 0 ? 1 : 0)
            let tableText = tableLines.joined(separator: "\n")
            let start = text.index(text.startIndex, offsetBy: startCharIndex)
            let end = text.index(start, offsetBy: tableText.count)

            tables.append((range: start..<end, lines: tableLines))
        }

        return tables
    }

    /// Checks if a line appears to be a table row (contains at least 2 pipe characters).
    private func isTableRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.hasPrefix("|") || trimmed.hasSuffix("|") else { return false }
        return trimmed.filter { $0 == "|" }.count >= 2
    }

    /// Checks if a line is a delimiter row (contains at least 3 dashes with optional alignment markers).
    private func isDelimiterRow(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        let pipes = trimmed.filter { $0 == "|" }
        guard pipes.count >= 1 else { return false }

        let cells = trimmed.components(separatedBy: "|").filter { !$0.isEmpty }
        guard cells.count >= 2 else { return false }

        return cells.allSatisfy { isDelimiterCell($0) }
    }

    /// Checks if a cell is a valid delimiter cell (contains only -, :, and spaces).
    private func isDelimiterCell(_ cell: String) -> Bool {
        let trimmed = cell.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count >= 3 else { return false }
        let dashColon = trimmed.filter { $0 == "-" || $0 == ":" }
        return dashColon.count == trimmed.count
    }

    // MARK: - Table Parsing

    /// Parses a table row into an array of cell contents.
    /// - Parameter row: The table row string to parse.
    /// - Returns: An array of cell contents with leading/trailing whitespace trimmed.
    func parseTableRow(_ row: String) -> [String] {
        let trimmed = row.trimmingCharacters(in: .whitespaces)

        // Handle rows without leading/trailing pipes
        var content = trimmed
        if trimmed.hasPrefix("|") {
            content = String(trimmed.dropFirst())
        }
        if trimmed.hasSuffix("|") {
            content = String(content.dropLast())
        }

        let cells = content.components(separatedBy: "|")
        return cells.map { $0.trimmingCharacters(in: .whitespaces) }
    }

    // MARK: - Column Width Calculation

    /// Calculates the optimal column widths and alignments from table rows.
    /// - Parameter rows: An array of rows, where each row is an array of cell strings.
    ///                  The first row should be the delimiter row with alignment markers.
    /// - Returns: An array of TableColumn objects defining width and alignment for each column.
    func calculateColumnWidths(rows: [[String]]) -> [TableColumn] {
        guard rows.count >= 2 else { return [] }

        // First row after header is the delimiter row - extract alignment from it
        let delimiterRow = rows[1]
        let alignments = delimiterRow.map { parseAlignment($0) }

        // Calculate max width for each column across all rows
        var columnWidths: [Int] = Array(repeating: 0, count: max(delimiterRow.count, rows.first?.count ?? 0))

        for row in rows where row.count == columnWidths.count {
            for (index, cell) in row.enumerated() {
                let visualWidth = visualWidth(of: cell)
                columnWidths[index] = max(columnWidths[index], visualWidth)
            }
        }

        // Ensure minimum width of 3 for delimiter row cells
        for (index, width) in columnWidths.enumerated() {
            columnWidths[index] = max(width, 3)
        }

        return zip(columnWidths, alignments).map { TableColumn(width: $0, alignment: $1) }
    }

    /// Parses alignment from a delimiter cell.
    private func parseAlignment(_ cell: String) -> ColumnAlignment {
        let trimmed = cell.trimmingCharacters(in: .whitespaces)

        if trimmed.hasPrefix(":") && trimmed.hasSuffix(":") {
            return .center
        } else if trimmed.hasSuffix(":") {
            return .right
        } else if trimmed.hasPrefix(":") {
            return .left
        }
        return .none
    }

    /// Calculates the visual width of a string, accounting for Unicode characters.
    /// CJK characters and emoji take 2 positions, others take 1.
    private func visualWidth(of string: String) -> Int {
        var width = 0
        for scalar in string.unicodeScalars {
            if isWideCharacter(scalar) {
                width += 2
            } else {
                width += 1
            }
        }
        return width
    }

    /// Checks if a Unicode scalar is a wide character (CJK, emoji, etc.).
    private func isWideCharacter(_ scalar: Unicode.Scalar) -> Bool {
        // CJK Unified Ideographs
        if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF { return true }
        // CJK Extension A
        if scalar.value >= 0x3400 && scalar.value <= 0x4DBF { return true }
        // CJK Extension B
        if scalar.value >= 0x20000 && scalar.value <= 0x2A6DF { return true }
        // Hiragana, Katakana, Hangul
        if scalar.value >= 0x3040 && scalar.value <= 0x309F { return true }
        if scalar.value >= 0x30A0 && scalar.value <= 0x30FF { return true }
        if scalar.value >= 0xAC00 && scalar.value <= 0xD7AF { return true }
        // Emoji and symbols
        if scalar.value >= 0x1F300 && scalar.value <= 0x1F9FF { return true }
        // Fullwidth forms
        if scalar.value >= 0xFF00 && scalar.value <= 0xFFEF { return true }
        return false
    }

    // MARK: - Cell Formatting

    /// Formats a cell content to fit within a column width with specified alignment.
    /// - Parameters:
    ///   - content: The cell content to format.
    ///   - width: The target width for the cell.
    ///   - alignment: The alignment to use for the content.
    /// - Returns: The formatted cell string padded with spaces.
    func formatCell(_ content: String, width: Int, alignment: ColumnAlignment) -> String {
        let visualW = visualWidth(of: content)
        let padding = width - visualW

        guard padding > 0 else { return content }

        switch alignment {
        case .left:
            return content + String(repeating: " ", count: padding)
        case .right:
            return String(repeating: " ", count: padding) + content
        case .center:
            let leftPad = padding / 2
            let rightPad = padding - leftPad
            return String(repeating: " ", count: leftPad) + content + String(repeating: " ", count: rightPad)
        case .none:
            return content + String(repeating: " ", count: padding)
        }
    }

    // MARK: - Table Formatting

    /// Formats a complete table with proper alignment and padding.
    /// - Parameter lines: The table lines (header, delimiter, and data rows).
    /// - Returns: The formatted table as a string.
    func formatTable(_ lines: [String]) -> String {
        guard lines.count >= 2 else { return lines.joined(separator: "\n") }

        // Parse all rows
        let rows = lines.map { parseTableRow($0) }

        // Calculate column widths and alignments
        let columns = calculateColumnWidths(rows: rows)

        guard !columns.isEmpty else { return lines.joined(separator: "\n") }

        // Build formatted rows
        var formattedRows: [String] = []

        for (rowIndex, row) in rows.enumerated() {
            // Handle delimiter row specially
            if rowIndex == 1 {
                formattedRows.append(formatDelimiterRow(columns: columns))
            } else {
                let cells = row + Array(repeating: "", count: max(0, columns.count - row.count))
                let formattedCells = zip(cells, columns).map { formatCell($0.0, width: $0.1.width, alignment: $0.1.alignment) }
                formattedRows.append("| " + formattedCells.joined(separator: " | ") + " |")
            }
        }

        return formattedRows.joined(separator: "\n")
    }

    /// Formats the delimiter row (e.g., |:---|---:|---|).
    private func formatDelimiterRow(columns: [TableColumn]) -> String {
        let cells = columns.map { column -> String in
            let dashes = String(repeating: "-", count: column.width)

            switch column.alignment {
            case .left:
                return ":" + String(dashes.dropFirst())
            case .right:
                return String(dashes.dropLast()) + ":"
            case .center:
                let count = dashes.count
                if count >= 2 {
                    let middle = String(dashes.dropFirst().dropLast())
                    return ":" + middle + ":"
                }
                return ":" + dashes + ":"
            case .none:
                return dashes
            }
        }

        return "| " + cells.joined(separator: " | ") + " |"
    }

    // MARK: - Document Formatting

    /// Formats all tables in a document, preserving non-table text.
    /// - Parameter text: The entire document text.
    /// - Returns: The document with all tables formatted.
    func formatEntireDocument(_ text: String) -> String {
        let tables = detectTableRanges(in: text)

        // Process tables from end to start to preserve indices
        var result = text
        for (range, lines) in tables.reversed() {
            let formatted = formatTable(lines)
            result.replaceSubrange(range, with: formatted)
        }

        return result
    }
}