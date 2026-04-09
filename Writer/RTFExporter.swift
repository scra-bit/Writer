import Foundation
import AppKit
import UniformTypeIdentifiers
import Markdown

/// Utility for exporting markdown documents as Rich Text Format (RTF) files
/// Converts HTML to NSAttributedString and writes as RTF
@MainActor
struct RTFExporter {
    let markdown: String
    let theme: PreviewTheme

    /// Presents save panel and exports markdown as RTF
    /// - Parameter suggestedName: Default filename suggestion
    /// - Returns: URL of saved file
    func save(suggestedName: String = "document.rtf") async throws -> URL {
        let html = generateHTML()

        // Present save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.rtf]
        savePanel.nameFieldStringValue = suggestedName
        savePanel.canCreateDirectories = true
        savePanel.title = "Export RTF"
        savePanel.message = "Choose where to save the RTF file"

        let response = await savePanel.beginSheetModal(for: NSApp.keyWindow!)

        guard response == .OK, let url = savePanel.url else {
            throw ExportError.cancelled
        }

        // Convert HTML to NSAttributedString
        guard let attributedString = htmlToAttributedString(html) else {
            throw ExportError.writeFailed(NSError(domain: "RTFExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert HTML to RTF"]))
        }

        // Write as RTF
        let range = NSRange(location: 0, length: attributedString.length)
        guard let rtfData = attributedString.rtf(from: range, documentAttributes: [:]) else {
            throw ExportError.writeFailed(NSError(domain: "RTFExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create RTF data"]))
        }

        try rtfData.write(to: url)

        return url
    }

    /// Converts HTML string to NSAttributedString
    private func htmlToAttributedString(_ html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else {
            return nil
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
    }

    /// Generates complete HTML document with inline CSS
    private func generateHTML() -> String {
        let bodyContent = renderBodyContent(markdown)
        return wrapInHTMLDocument(bodyContent)
    }

    /// Renders markdown to HTML body content
    private func renderBodyContent(_ markdown: String) -> String {
        let escaped = escapeHTMLEntities(markdown)

        let document = Document(parsing: escaped)
        var visitor = HTMLVisitor()
        var html = document.accept(&visitor)

        // Process custom ==highlight== syntax
        html = processHighlights(html)

        return html
    }

    /// Escapes HTML special characters
    private func escapeHTMLEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// Processes custom ==highlight== syntax
    private func processHighlights(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "==(.+?)==", options: []) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "<mark class=\"highlight\">$1</mark>"
        )
    }

    /// Wraps content in complete HTML document with inline CSS
    private func wrapInHTMLDocument(_ bodyContent: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
        \(theme.cssStyles)
            </style>
        </head>
        <body>
            \(bodyContent)
        </body>
        </html>
        """
    }
}
