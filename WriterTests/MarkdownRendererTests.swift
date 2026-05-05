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

    func testRenderBodyContentTranscludesMarkdownContentBlocks() throws {
        let rootURL = try makeTemporaryWorkspace()
        let chaptersURL = rootURL.appendingPathComponent("chapters", isDirectory: true)
        try FileManager.default.createDirectory(at: chaptersURL, withIntermediateDirectories: true)

        let sourceURL = rootURL.appendingPathComponent("draft.md")
        let transcludedURL = chaptersURL.appendingPathComponent("intro.md")

        try """
        ## Imported

        Nested ==highlight== content.
        """.write(to: transcludedURL, atomically: true, encoding: .utf8)

        try """
        # Draft

        \(transcludedURL.path) "Intro"
        """.write(to: sourceURL, atomically: true, encoding: .utf8)

        let html = MarkdownRenderer.renderBodyContent(
            try String(contentsOf: sourceURL, encoding: .utf8),
            context: MarkdownRenderContext(documentURL: sourceURL, workspaceRootURL: rootURL)
        )

        XCTAssertTrue(html.contains("<h1>Draft</h1>"), html)
        XCTAssertTrue(html.contains("<h2>Imported</h2>"), html)
        XCTAssertTrue(html.contains("<figcaption class=\"content-block-caption\">Intro</figcaption>"), html)
        XCTAssertTrue(html.contains("<mark class=\"highlight\">highlight</mark>"), html)
    }

    func testRenderBodyContentShowsWarningForMissingContentBlock() {
        let html = MarkdownRenderer.renderBodyContent(
            "/missing/chapter.md",
            context: MarkdownRenderContext(documentURL: nil, workspaceRootURL: nil)
        )

        XCTAssertTrue(html.contains("Missing content block"), html)
        XCTAssertTrue(html.contains("/missing/chapter.md"), html)
    }

    func testRenderBodyContentRendersCSVContentBlocksAsTable() throws {
        let rootURL = try makeTemporaryWorkspace()
        let sourceURL = rootURL.appendingPathComponent("draft.md")
        let csvURL = rootURL.appendingPathComponent("budget.csv")

        try """
        Name,Amount
        Rent,1200
        Utilities,180
        """.write(to: csvURL, atomically: true, encoding: .utf8)

        try "\(csvURL.path) (Budget)".write(to: sourceURL, atomically: true, encoding: .utf8)

        let html = MarkdownRenderer.renderBodyContent(
            try String(contentsOf: sourceURL, encoding: .utf8),
            context: MarkdownRenderContext(documentURL: sourceURL, workspaceRootURL: rootURL)
        )

        XCTAssertTrue(html.contains("<th>Name</th>"), html)
        XCTAssertTrue(html.contains("<td>1200</td>"), html)
        XCTAssertTrue(html.contains("Budget"), html)
    }

    func testRenderBodyContentDoesNotTreatPlainFilenameAsContentBlock() {
        let html = MarkdownRenderer.renderBodyContent("chapter.md")

        XCTAssertTrue(html.contains("<p>chapter.md</p>"), html)
        XCTAssertFalse(html.contains("content-block"), html)
    }

    func testRenderBodyContentRendersTableOfContentsFromTOC() {
        let markdown = """
        {{TOC}}

        # Introduction

        ## Background

        ### Details

        ## Conclusion
        """

        let html = MarkdownRenderer.renderBodyContent(markdown)

        XCTAssertTrue(html.contains("<nav class=\"toc\">"), html)
        XCTAssertTrue(html.contains("<a href=\"#heading-1-introduction\">Introduction</a>"), html)
        XCTAssertTrue(html.contains("<a href=\"#heading-2-background\">Background</a>"), html)
        XCTAssertTrue(html.contains("<a href=\"#heading-3-details\">Details</a>"), html)
        XCTAssertTrue(html.contains("<a href=\"#heading-2-conclusion\">Conclusion</a>"), html)
    }

    func testRenderBodyContentTOCLinksMatchHeadingIDs() {
        let markdown = """
        {{TOC}}

        # First Heading

        # Second Heading
        """

        let html = MarkdownRenderer.renderBodyContent(markdown)

        // Check heading IDs are present
        XCTAssertTrue(html.contains("id=\"heading-1-first-heading\""), html)
        XCTAssertTrue(html.contains("id=\"heading-1-second-heading-2\""), html)

        // Check TOC links match
        XCTAssertTrue(html.contains("href=\"#heading-1-first-heading\""), html)
        XCTAssertTrue(html.contains("href=\"#heading-1-second-heading-2\""), html)
    }

    func testRenderBodyContentTOCWithNestedHeadings() {
        let markdown = """
        {{TOC}}

        # Chapter 1

        ## Section 1.1

        ### Subsection 1.1.1

        ## Section 1.2

        # Chapter 2
        """

        let html = MarkdownRenderer.renderBodyContent(markdown)

        XCTAssertTrue(html.contains("<nav class=\"toc\">"), html)
        // Check nested list structure
        XCTAssertTrue(html.contains("<ul>"), html)
        XCTAssertTrue(html.contains("</ul>"), html)
    }

    func testRenderBodyContentTOCWithNoHeadings() {
        let markdown = """
        {{TOC}}

        Just some text without headings.
        """

        let html = MarkdownRenderer.renderBodyContent(markdown)

        XCTAssertTrue(html.contains("<!-- No headings found for TOC -->"), html)
    }

    func testRenderBodyContentTOCWithSpecialCharactersInHeading() {
        let markdown = """
        {{TOC}}

        # Hello World!

        # Code `example`
        """

        let html = MarkdownRenderer.renderBodyContent(markdown)

        XCTAssertTrue(html.contains("id=\"heading-1-hello-world\""), html)
        XCTAssertTrue(html.contains("id=\"heading-1-code-example\""), html)
    }

    private func makeTemporaryWorkspace() throws -> URL {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: rootURL)
        }
        return rootURL
    }
}
