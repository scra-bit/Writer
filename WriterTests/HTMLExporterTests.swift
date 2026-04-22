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
}
