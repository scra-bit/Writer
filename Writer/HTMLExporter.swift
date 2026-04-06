import Foundation
import Markdown
import AppKit
import UniformTypeIdentifiers

/// Utility for exporting markdown documents as standalone HTML files
struct HTMLExporter {
    let markdown: String
    let theme: PreviewTheme
    
    /// Generates a complete standalone HTML document with inline CSS
    func generateHTML() -> String {
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
    
    /// Presents save panel and writes HTML to selected location
    /// - Parameter suggestedName: Default filename suggestion
    /// - Returns: URL of saved file
    func save(suggestedName: String = "document.html") async throws -> URL {
        let html = generateHTML()
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.html]
        savePanel.nameFieldStringValue = suggestedName
        savePanel.canCreateDirectories = true
        savePanel.title = "Export HTML"
        savePanel.message = "Choose where to save the HTML file"
        
        let response = await savePanel.beginSheetModal(for: NSApp.keyWindow!)
        
        guard response == .OK, let url = savePanel.url else {
            throw ExportError.cancelled
        }
        
        try html.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

enum ExportError: LocalizedError {
    case cancelled
    case writeFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Export was cancelled"
        case .writeFailed(let error):
            return "Failed to save file: \(error.localizedDescription)"
        }
    }
}
