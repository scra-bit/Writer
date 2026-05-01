import XCTest
@testable import Writer

final class HTMLExporterTests: XCTestCase {
    func testGenerateHTMLBuildsStandaloneDocument() {
        let exporter = HTMLExporter(
            markdown: "# Export\n\nBody with ==highlight==.",
            theme: .sansSerif
        )

        let html = exporter.generateHTML()

        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("<h1>Export</h1>"))
        XCTAssertTrue(html.contains("<mark class=\"highlight\">highlight</mark>"))
        XCTAssertTrue(html.contains(PreviewTheme.sansSerif.bodyFontFamily))
    }

    func testGenerateHTMLResolvesContentBlocksFromRenderContext() throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: rootURL)
        }

        let chapterURL = rootURL.appendingPathComponent("chapter.md")
        try "# Imported".write(to: chapterURL, atomically: true, encoding: .utf8)

        let exporter = HTMLExporter(
            markdown: chapterURL.path,
            theme: .sansSerif,
            renderContext: MarkdownRenderContext(
                documentURL: rootURL.appendingPathComponent("draft.md"),
                workspaceRootURL: rootURL
            )
        )

        let html = exporter.generateHTML()

        XCTAssertTrue(html.contains("<h1>Imported</h1>"), html)
    }
}
