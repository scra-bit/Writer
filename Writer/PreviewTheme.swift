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
    static let lightTheme = PreviewTheme(
        name: "Light",
        bodyFontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        headingFontFamily: "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        codeFontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
        baseFontSize: 16,
        lineHeight: 1.6,
        backgroundColor: "#ffffff",
        textColor: "#262626", // neutral-800 equivalent
        linkColor: "#0366d6", // blue-600
        codeBackgroundColor: "#fafafa", // neutral-50 equivalent
        borderColor: "#e5e5e5", // neutral-200 equivalent
        secondaryTextColor: "#525252" // neutral-600 equivalent
    )

    // Cream Theme - Like an old book page, warm and readable
    static let cream = PreviewTheme(
        name: "Cream",
        bodyFontFamily: "Charter, 'Bitstream Charter', 'Sitka Text', Cambria, serif",
        headingFontFamily: "Charter, 'Bitstream Charter', 'Sitka Text', Cambria, serif",
        codeFontFamily: "'SF Mono', Menlo, Monaco, monospace",
        baseFontSize: 17,
        lineHeight: 1.7,
        backgroundColor: "#fdf6e3",
        textColor: "#3d3529",
        linkColor: "#6b4c1e",
        codeBackgroundColor: "#efe6d5",
        borderColor: "#d4c9b0",
        secondaryTextColor: "#6b5d4a"
    )

    // Slate Theme - Clean document like a newspaper or magazine
    static let slate = PreviewTheme(
        name: "Slate",
        bodyFontFamily: "'Newsreader', 'Iowan Old Style', Georgia, serif",
        headingFontFamily: "'Newsreader', 'Iowan Old Style', Georgia, serif",
        codeFontFamily: "'SF Mono', Menlo, Monaco, monospace",
        baseFontSize: 16,
        lineHeight: 1.6,
        backgroundColor: "#f8f9fa",
        textColor: "#212529",
        linkColor: "#0d6efd",
        codeBackgroundColor: "#e9ecef",
        borderColor: "#dee2e6",
        secondaryTextColor: "#6c757d"
    )

    // Sepia Theme - Like an aged manuscript
    static let sepia = PreviewTheme(
        name: "Sepia",
        bodyFontFamily: "'Crimson Pro', 'Crimson Text', Georgia, serif",
        headingFontFamily: "'Crimson Pro', 'Crimson Text', Georgia, serif",
        codeFontFamily: "'SF Mono', Menlo, Monaco, monospace",
        baseFontSize: 18,
        lineHeight: 1.7,
        backgroundColor: "#f4ecd8",
        textColor: "#5c4b37",
        linkColor: "#8b5a2b",
        codeBackgroundColor: "#e8dfc7",
        borderColor: "#c9bca0",
        secondaryTextColor: "#7a6b52"
    )

    // Notebook Theme - Like a spiral notebook with faint lines
    static let notebook = PreviewTheme(
        name: "Notebook",
        bodyFontFamily: "'Refrigerator', 'Charter', Georgia, serif",
        headingFontFamily: "'Refrigerator', 'Charter', Georgia, serif",
        codeFontFamily: "'SF Mono', Menlo, Monaco, monospace",
        baseFontSize: 15,
        lineHeight: 1.8,
        backgroundColor: "#fffef7",
        textColor: "#2c2c2c",
        linkColor: "#2563eb",
        codeBackgroundColor: "#f0f0e8",
        borderColor: "#e5e5db",
        secondaryTextColor: "#6b6b6b"
    )

    // Modern Theme - Clean editorial magazine style
    static let modern = PreviewTheme(
        name: "Modern",
        bodyFontFamily: "'Söhne', 'SF Pro Text', -apple-system, sans-serif",
        headingFontFamily: "'Söhne Breit', 'SF Pro Display', -apple-system, sans-serif",
        codeFontFamily: "'SF Mono', Menlo, monospace",
        baseFontSize: 15,
        lineHeight: 1.65,
        backgroundColor: "#ffffff",
        textColor: "#111111",
        linkColor: "#000000",
        codeBackgroundColor: "#f5f5f5",
        borderColor: "#e0e0e0",
        secondaryTextColor: "#555555"
    )

    // All available themes
    static let allThemes: [PreviewTheme] = [.sansSerif, .serif, .lightTheme, .cream, .slate, .sepia, .notebook, .modern]
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
