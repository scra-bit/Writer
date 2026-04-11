import XCTest
@testable import Writer

final class HTMLExporterTests: XCTestCase {
    
    private let testTheme = PreviewTheme.sansSerif
    
    // MARK: - HTML5 Structure Tests
    
    func testGenerateHTMLProducesValidHTML5Structure() {
        let markdown = "# Hello World"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE html>"), "HTML should start with DOCTYPE declaration")
        XCTAssertTrue(html.contains("<html>"), "HTML should contain <html> tag")
        XCTAssertTrue(html.contains("</html>"), "HTML should contain closing </html> tag")
        XCTAssertTrue(html.contains("<head>"), "HTML should contain <head> tag")
        XCTAssertTrue(html.contains("</head>"), "HTML should contain closing </head> tag")
        XCTAssertTrue(html.contains("<body>"), "HTML should contain <body> tag")
        XCTAssertTrue(html.contains("</body>"), "HTML should contain closing </body> tag")
        XCTAssertTrue(html.contains("<meta charset=\"utf-8\">"), "HTML should contain charset meta tag")
    }
    
    // MARK: - HTML Entity Escaping Tests
    
    func testGenerateHTMLEscapesAmpersand() {
        let markdown = "Tom & Jerry"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("&amp;"), "Ampersand should be escaped to &amp;")
        XCTAssertFalse(html.contains("& Jerry"), "Unescaped ampersand should not appear")
    }
    
    func testGenerateHTMLEscapesLessThan() {
        let markdown = "a < b"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("&lt;"), "Less than should be escaped to &lt;")
        XCTAssertFalse(html.contains("a < b"), "Unescaped less than should not appear")
    }
    
    func testGenerateHTMLEscapesGreaterThan() {
        let markdown = "b > a"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("&gt;"), "Greater than should be escaped to &gt;")
        XCTAssertFalse(html.contains("b > a"), "Unescaped greater than should not appear")
    }
    
    func testGenerateHTMLEscapesAllSpecialCharacters() {
        let markdown = "A & B < C > D"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("&amp;"), "HTML should contain escaped ampersand")
        XCTAssertTrue(html.contains("&lt;"), "HTML should contain escaped less than")
        XCTAssertTrue(html.contains("&gt;"), "HTML should contain escaped greater than")
    }
    
    // MARK: - Highlight Processing Tests
    
    func testGenerateHTMLConvertsHighlightMarkers() {
        let markdown = "This is ==marked== text"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("<mark class=\"highlight\">"), "Highlight markers should be converted to <mark class=\"highlight\">")
        XCTAssertTrue(html.contains("</mark>"), "Highlight should have closing </mark> tag")
    }
    
    func testGenerateHTMLProcessesHighlightContentCorrectly() {
        let markdown = "==important=="
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("<mark class=\"highlight\">important</mark>"), "Highlight content should be preserved inside mark tags")
    }
    
    func testGenerateHTMLHandlesMultipleHighlights() {
        let markdown = "First ==highlight== and second ==highlight=="
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        let highlightCount = html.components(separatedBy: "<mark class=\"highlight\">").count - 1
        XCTAssertEqual(highlightCount, 2, "Should have two highlight markers")
    }
    
    // MARK: - Edge Case Tests
    
    func testGenerateHTMLWithEmptyMarkdown() {
        let markdown = ""
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE html>"), "Empty markdown should still produce valid HTML5 structure")
        XCTAssertTrue(html.contains("<body>"), "Empty markdown should still produce body tag")
        XCTAssertTrue(html.contains("</body>"), "Empty markdown should still produce closing body tag")
    }
    
    func testGenerateHTMLWithWhitespaceOnly() {
        let markdown = "   \n\t  \n   "
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.hasPrefix("<!DOCTYPE html>"), "Whitespace-only markdown should still produce valid HTML5 structure")
    }
    
    func testGenerateHTMLWithSpecialHTMLCharactersOnly() {
        let markdown = "& < >"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("&amp;"), "Should escape ampersand")
        XCTAssertTrue(html.contains("&lt;"), "Should escape less than")
        XCTAssertTrue(html.contains("&gt;"), "Should escape greater than")
    }
    
    func testGenerateHTMLIncludesThemeStyles() {
        let markdown = "Hello"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("<style>"), "HTML should contain style tag")
        XCTAssertTrue(html.contains("body {"), "HTML should include body styles from theme")
    }
    
    // MARK: - Integration Tests
    
    func testGenerateHTMLRendersHeading() {
        let markdown = "# Test Heading"
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("<h1"), "HTML should contain h1 tag for heading")
        XCTAssertTrue(html.contains("Test Heading"), "Heading content should be preserved")
    }
    
    func testGenerateHTMLRendersParagraph() {
        let markdown = "This is a paragraph."
        let exporter = HTMLExporter(markdown: markdown, theme: testTheme)
        
        let html = exporter.generateHTML()
        
        XCTAssertTrue(html.contains("<p>"), "HTML should contain paragraph tags")
        XCTAssertTrue(html.contains("This is a paragraph."), "Paragraph content should be preserved")
    }
}