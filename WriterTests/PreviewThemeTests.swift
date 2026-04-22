import XCTest
@testable import Writer

final class PreviewThemeTests: XCTestCase {
    func testAllThemesContainsExpectedBuiltIns() {
        XCTAssertEqual(PreviewTheme.allThemes, [.sansSerif, .serif])
    }

    func testCSSStylesIncludesThemeValuesAndPrintRules() {
        let css = PreviewTheme.serif.cssStyles

        XCTAssertTrue(css.contains(PreviewTheme.serif.bodyFontFamily))
        XCTAssertTrue(css.contains(PreviewTheme.serif.textColor))
        XCTAssertTrue(css.contains("@media print"))
        XCTAssertTrue(css.contains("page-break-after: avoid"))
    }
}
