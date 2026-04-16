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
        let bodyContent = MarkdownRenderer.renderBodyContent(markdown)
        return MarkdownRenderer.wrapInHTMLDocument(bodyContent, theme: theme)
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
