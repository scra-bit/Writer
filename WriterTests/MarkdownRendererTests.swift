import XCTest
@testable import Writer

final class MarkdownRendererTests: XCTestCase {
    func testRenderBodyContentEscapesHTMLAndRendersMarkdown() {
        let markdown = """
        # Title

        Paragraph with **bold** and <script>.
        """

        let html = MarkdownRenderer.renderBodyContent(markdown)

        XCTAssertTrue(html.contains("<h1>Title</h1>"), html)
        XCTAssertTrue(html.contains("<strong>bold</strong>"), html)
        XCTAssertFalse(html.contains("<script>"), html)
        XCTAssertTrue(html.contains("&lt;script"), html)
    }

    func testRenderBodyContentProcessesHighlightSyntax() {
        let html = MarkdownRenderer.renderBodyContent("A ==highlighted== word.")

        XCTAssertTrue(html.contains("<mark class=\"highlight\">highlighted</mark>"))
    }

    func testWrapInHTMLDocumentIncludesThemeCSSAndBodyContent() {
        let bodyContent = "<p>Hello</p>"
        let html = MarkdownRenderer.wrapInHTMLDocument(bodyContent, theme: .serif)

        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains(bodyContent))
        XCTAssertTrue(html.contains(PreviewTheme.serif.bodyFontFamily))
        XCTAssertTrue(html.contains("@media print"))
    }
}
