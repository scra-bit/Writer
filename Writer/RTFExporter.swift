//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
import Foundation
import AppKit
import UniformTypeIdentifiers

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
        let bodyContent = MarkdownRenderer.renderBodyContent(markdown)
        let html = MarkdownRenderer.wrapInHTMLDocument(bodyContent, theme: theme)

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
}
