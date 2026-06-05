import XCTest

@testable import Writer

final class PreviewThemeTests: XCTestCase {
    func testAllThemesContainsLightAndDarkVariants() {
        XCTAssertEqual(PreviewTheme.allThemes.count, 4)
        XCTAssertTrue(PreviewTheme.allThemes.contains(.sansSerifLight))
        XCTAssertTrue(PreviewTheme.allThemes.contains(.sansSerifDark))
        XCTAssertTrue(PreviewTheme.allThemes.contains(.serifLight))
        XCTAssertTrue(PreviewTheme.allThemes.contains(.serifDark))
    }

    func testCSSStylesIncludesThemeValuesAndPrintRules() {
        let css = PreviewTheme.serifLight.cssStyles

        XCTAssertTrue(css.contains(PreviewTheme.serifLight.bodyFontFamily))
        XCTAssertTrue(css.contains(PreviewTheme.serifLight.textColor))
        XCTAssertTrue(css.contains("@media print"))
        XCTAssertTrue(css.contains("page-break-after: avoid"))
    }

    func testDarkThemeHasDarkColors() {
        let darkCSS = PreviewTheme.sansSerifDark.cssStyles
        XCTAssertTrue(darkCSS.contains("#0d1117"))  // dark background
        XCTAssertTrue(darkCSS.contains("#c9d1d9"))  // dark text
        XCTAssertTrue(darkCSS.contains("#58a6ff"))  // dark link color
    }

    func testLightThemeHasLightColors() {
        let lightCSS = PreviewTheme.sansSerifLight.cssStyles
        XCTAssertTrue(lightCSS.contains("#ffffff"))  // light background
        XCTAssertTrue(lightCSS.contains("#24292e"))  // light text
        XCTAssertTrue(lightCSS.contains("#0366d6"))  // light link color
    }

    func testBackwardCompatibilityAliasesExist() {
        // These aliases should exist for backward compatibility
        XCTAssertNotNil(PreviewTheme.sansSerif)
        XCTAssertNotNil(PreviewTheme.serif)
        XCTAssertEqual(PreviewTheme.sansSerif.colorMode, .light)
        XCTAssertEqual(PreviewTheme.serif.colorMode, .light)
    }

    func testWarningBlockHasDarkModeColors() {
        let css = PreviewTheme.sansSerifDark.cssStyles
        XCTAssertTrue(css.contains("@media (prefers-color-scheme: dark)"))
        XCTAssertTrue(css.contains("#2b2000"))  // dark warning background
    }
}
