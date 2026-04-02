import Foundation

struct PreviewTheme: Hashable {
    let name: String

    // Typography
    let bodyFontFamily: String
    let headingFontFamily: String
    let codeFontFamily: String
    let baseFontSize: Int
    let lineHeight: Double

    // Colors (neutral palette)
    let backgroundColor: String
    let textColor: String
    let linkColor: String
    let codeBackgroundColor: String
    let borderColor: String
    let secondaryTextColor: String
}

extension PreviewTheme {
    // Sans Serif Theme (default)
    static let sansSerif = PreviewTheme(
        name: "Sans Serif",
        bodyFontFamily: "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif",
        headingFontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        codeFontFamily: "'SF Mono', Menlo, Monaco, 'Courier New', monospace",
        baseFontSize: 16,
        lineHeight: 1.6,
        backgroundColor: "#ffffff",
        textColor: "#24292e",
        linkColor: "#0366d6",
        codeBackgroundColor: "#f6f8fa",
        borderColor: "#e1e4e8",
        secondaryTextColor: "#6a737d"
    )

    // Serif Theme
    static let serif = PreviewTheme(
        name: "Serif",
        bodyFontFamily: "Georgia, 'Times New Roman', Times, serif",
        headingFontFamily: "Georgia, 'Times New Roman', Times, serif",
        codeFontFamily: "'SF Mono', Menlo, Monaco, 'Courier New', monospace",
        baseFontSize: 16,
        lineHeight: 1.6,
        backgroundColor: "#ffffff",
        textColor: "#24292e",
        linkColor: "#0366d6",
        codeBackgroundColor: "#f6f8fa",
        borderColor: "#e1e4e8",
        secondaryTextColor: "#6a737d"
    )

    // All available themes
    static let allThemes: [PreviewTheme] = [.sansSerif, .serif]
}

extension PreviewTheme {
    // Generate CSS from theme values
    var cssStyles: String {
        """
        * {
            box-sizing: border-box;
        }
        body {
            font-family: \(bodyFontFamily);
            font-size: \(baseFontSize)px;
            line-height: \(lineHeight);
            color: \(textColor);
            background-color: \(backgroundColor);
            padding: 16px;
            margin: 0;
            max-width: 100%;
            overflow-x: hidden;
        }
        h1, h2, h3, h4, h5, h6 {
            font-family: \(headingFontFamily);
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        h1 { font-size: 2em; padding-bottom: 0.3em; }
        h2 { font-size: 1.5em; padding-bottom: 0.3em; }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1em; }
        h5 { font-size: 0.875em; }
        h6 { font-size: 0.85em; color: \(secondaryTextColor); }
        p {
            margin-top: 0;
            margin-bottom: 16px;
        }
        a {
            color: \(linkColor);
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        code {
            font-family: \(codeFontFamily);
            font-size: 85%;
            padding: 0.2em 0.4em;
            background-color: \(codeBackgroundColor);
            border-radius: 3px;
        }
        pre {
            font-family: \(codeFontFamily);
            padding: 16px;
            overflow: auto;
            font-size: 85%;
            line-height: 1.45;
            background-color: \(codeBackgroundColor);
            border-radius: 6px;
        }
        pre code {
            padding: 0;
            background-color: transparent;
        }
        blockquote {
            margin: 0 0 16px 0;
            padding: 0 1em;
            color: \(secondaryTextColor);
            border-left: 4px solid \(borderColor);
        }
        ul, ol {
            margin-top: 0;
            margin-bottom: 16px;
            padding-left: 2em;
        }
        li {
            margin-bottom: 4px;
        }
        hr {
            height: 0.25em;
            padding: 0;
            margin: 24px 0;
            background-color: \(borderColor);
            border: 0;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 16px;
        }
        th, td {
            padding: 8px 12px;
            border: 1px solid \(borderColor);
        }
        th {
            background-color: \(codeBackgroundColor);
            font-weight: 600;
        }
        img {
            max-width: 100%;
            height: auto;
        }
        """
    }
}
