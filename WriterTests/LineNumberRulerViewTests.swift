import XCTest

@testable import Writer

final class LineNumberRulerViewTests: XCTestCase {
    private func lineNumber(_ index: Int, in string: String) -> Int {
        LineNumberRulerView.lineNumber(forCharacterIndex: index, in: string as NSString)
    }

    func testFirstCharacterIsLineOne() {
        XCTAssertEqual(lineNumber(0, in: "hello\nworld"), 1)
    }

    func testCharacterAfterNewlineIsNextLine() {
        let text = "hello\nworld"
        let secondLineStart = text.distance(
            from: text.startIndex, to: text.firstIndex(of: "w")!)
        XCTAssertEqual(lineNumber(secondLineStart, in: text), 2)
    }

    func testCountsMultipleLines() {
        let text = "a\nb\nc\nd"
        XCTAssertEqual(lineNumber(text.utf16.count, in: text), 4)
    }

    func testIndexOnNewlineStaysOnCurrentLine() {
        // The newline character itself still belongs to the line it terminates.
        let text = "alpha\nbeta"
        let newlineIndex = 5
        XCTAssertEqual(lineNumber(newlineIndex, in: text), 1)
    }

    func testEmptyStringIsLineOne() {
        XCTAssertEqual(lineNumber(0, in: ""), 1)
    }
}
