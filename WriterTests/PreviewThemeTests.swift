import XCTest
@testable import Writer

final class PreviewThemeTests: XCTestCase {

    // MARK: - Static Theme Existence Tests

    func testSansSerifThemeExists() {
        let theme = PreviewTheme.sansSerif
        XCTAssertEqual(theme.name, "Sans Serif", "Sans Serif theme should have correct name")
        XCTAssertFalse(theme.bodyFontFamily.isEmpty, "Sans Serif should have body font family")
        XCTAssertFalse(theme.headingFontFamily.isEmpty, "Sans Serif should have heading font family")
        XCTAssertFalse(theme.codeFontFamily.isEmpty, "Sans Serif should have code font family")
        XCTAssertEqual(theme.baseFontSize, 16, "Sans Serif should have base font size 16")
        XCTAssertEqual(theme.lineHeight, 1.6, "Sans Serif should have line height 1.6")
        XCTAssertFalse(theme.backgroundColor.isEmpty, "Sans Serif should have background color")
        XCTAssertFalse(theme.textColor.isEmpty, "Sans Serif should have text color")
        XCTAssertFalse(theme.linkColor.isEmpty, "Sans Serif should have link color")
        XCTAssertFalse(theme.codeBackgroundColor.isEmpty, "Sans Serif should have code background color")
        XCTAssertFalse(theme.borderColor.isEmpty, "Sans Serif should have border color")
        XCTAssertFalse(theme.secondaryTextColor.isEmpty, "Sans Serif should have secondary text color")
    }

    func testSerifThemeExists() {
        let theme = PreviewTheme.serif
        XCTAssertEqual(theme.name, "Serif", "Serif theme should have correct name")
        XCTAssertFalse(theme.bodyFontFamily.isEmpty, "Serif should have body font family")
        XCTAssertFalse(theme.headingFontFamily.isEmpty, "Serif should have heading font family")
        XCTAssertFalse(theme.codeFontFamily.isEmpty, "Serif should have code font family")
        XCTAssertEqual(theme.baseFontSize, 16, "Serif should have base font size 16")
        XCTAssertEqual(theme.lineHeight, 1.6, "Serif should have line height 1.6")
        XCTAssertFalse(theme.backgroundColor.isEmpty, "Serif should have background color")
        XCTAssertFalse(theme.textColor.isEmpty, "Serif should have text color")
        XCTAssertFalse(theme.linkColor.isEmpty, "Serif should have link color")
        XCTAssertFalse(theme.codeBackgroundColor.isEmpty, "Serif should have code background color")
        XCTAssertFalse(theme.borderColor.isEmpty, "Serif should have border color")
        XCTAssertFalse(theme.secondaryTextColor.isEmpty, "Serif should have secondary text color")
    }

    func testLightThemeExists() {
        let theme = PreviewTheme.lightTheme
        XCTAssertEqual(theme.name, "Light", "Light theme should have correct name")
        XCTAssertFalse(theme.bodyFontFamily.isEmpty, "Light should have body font family")
        XCTAssertFalse(theme.headingFontFamily.isEmpty, "Light should have heading font family")
        XCTAssertFalse(theme.codeFontFamily.isEmpty, "Light should have code font family")
        XCTAssertEqual(theme.baseFontSize, 16, "Light should have base font size 16")
        XCTAssertEqual(theme.lineHeight, 1.6, "Light should have line height 1.6")
        XCTAssertFalse(theme.backgroundColor.isEmpty, "Light should have background color")
        XCTAssertFalse(theme.textColor.isEmpty, "Light should have text color")
        XCTAssertFalse(theme.linkColor.isEmpty, "Light should have link color")
        XCTAssertFalse(theme.codeBackgroundColor.isEmpty, "Light should have code background color")
        XCTAssertFalse(theme.borderColor.isEmpty, "Light should have border color")
        XCTAssertFalse(theme.secondaryTextColor.isEmpty, "Light should have secondary text color")
    }

    // MARK: - All Themes Count Test

    func testAllThemesContainsExactlyThreeThemes() {
        XCTAssertEqual(PreviewTheme.allThemes.count, 3, "allThemes should contain exactly 3 themes")
    }

    func testAllThemesContainsCorrectThemes() {
        let themes = PreviewTheme.allThemes
        XCTAssertTrue(themes.contains(PreviewTheme.sansSerif), "allThemes should contain sansSerif")
        XCTAssertTrue(themes.contains(PreviewTheme.serif), "allThemes should contain serif")
        XCTAssertTrue(themes.contains(PreviewTheme.lightTheme), "allThemes should contain lightTheme")
    }

    // MARK: - CSS Selectors Test

    func testCssStylesContainsRequiredSelectors() {
        let css = PreviewTheme.sansSerif.cssStyles

        let requiredSelectors = ["h1", "h2", "h3", "h4", "h5", "h6", "p", "a", "code", "pre", "blockquote", "ul", "ol", "li", "hr", "table", "th", "td", "img"]

        for selector in requiredSelectors {
            XCTAssertTrue(css.contains(selector), "CSS should contain \(selector) selector")
        }
    }

    // MARK: - CSS Syntax Validity Tests

    func testCssStylesGeneratesValidSyntax() {
        let css = PreviewTheme.sansSerif.cssStyles

        // Check for balanced braces
        let openBraces = css.filter { $0 == "{" }.count
        let closeBraces = css.filter { $0 == "}" }.count
        XCTAssertEqual(openBraces, closeBraces, "CSS should have balanced braces")

        // Check for required properties
        XCTAssertTrue(css.contains("font-family:"), "CSS should contain font-family property")
        XCTAssertTrue(css.contains("font-size:"), "CSS should contain font-size property")
        XCTAssertTrue(css.contains("color:"), "CSS should contain color property")
        XCTAssertTrue(css.contains("background-color:"), "CSS should contain background-color property")
    }

    func testAllThemesGenerateValidCSS() {
        for theme in PreviewTheme.allThemes {
            let css = theme.cssStyles
            let openBraces = css.filter { $0 == "{" }.count
            let closeBraces = css.filter { $0 == "}" }.count
            XCTAssertEqual(openBraces, closeBraces, "Theme \(theme.name) should have balanced CSS braces")
        }
    }

    // MARK: - Font Family Specificity Tests

    func testSansSerifCssContainsSpecificFontFamily() {
        let css = PreviewTheme.sansSerif.cssStyles
        XCTAssertTrue(css.contains("-apple-system"), "Sans Serif CSS should contain -apple-system font")
    }

    func testSerifCssContainsSpecificFontFamily() {
        let css = PreviewTheme.serif.cssStyles
        XCTAssertTrue(css.contains("Georgia"), "Serif CSS should contain Georgia font")
    }

    func testLightThemeCssContainsSpecificFontFamily() {
        let css = PreviewTheme.lightTheme.cssStyles
        XCTAssertTrue(css.contains("system-ui"), "Light theme CSS should contain system-ui font")
    }

    func testEachThemeCssContainsItsBodyFontFamily() {
        for theme in PreviewTheme.allThemes {
            let css = theme.cssStyles
            // Each theme's body font should appear in its CSS
            XCTAssertTrue(css.contains(theme.bodyFontFamily.components(separatedBy: ",").first ?? ""),
                          "Theme \(theme.name) CSS should contain its body font family")
        }
    }

    func testEachThemeCssContainsItsHeadingFontFamily() {
        for theme in PreviewTheme.allThemes {
            let css = theme.cssStyles
            // Each theme's heading font should appear in its CSS
            XCTAssertTrue(css.contains(theme.headingFontFamily.components(separatedBy: ",").first ?? ""),
                          "Theme \(theme.name) CSS should contain its heading font family")
        }
    }

    func testEachThemeCssContainsItsCodeFontFamily() {
        for theme in PreviewTheme.allThemes {
            let css = theme.cssStyles
            // Each theme's code font should appear in its CSS
            XCTAssertTrue(css.contains(theme.codeFontFamily.components(separatedBy: ",").first ?? ""),
                          "Theme \(theme.name) CSS should contain its code font family")
        }
    }
}
