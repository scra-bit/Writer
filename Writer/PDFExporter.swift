import Foundation
import WebKit
import AppKit
import UniformTypeIdentifiers

/// Utility for exporting markdown documents as PDF files
/// Uses a hidden WebView to render HTML, then WKWebView.pdf() to generate PDF
@MainActor
struct PDFExporter {
    let markdown: String
    let theme: PreviewTheme

    /// Page width in points (US Letter)
    private let pageWidth: CGFloat = 612
    /// Page height in points (US Letter)
    private let pageHeight: CGFloat = 792
    /// Page margins in points
    private let pageMargin: CGFloat = 72

    /// Presents save panel and exports markdown as PDF
    /// - Parameter suggestedName: Default filename suggestion
    /// - Returns: URL of saved file
    func save(suggestedName: String = "document.pdf") async throws -> URL {
        let bodyContent = MarkdownRenderer.renderBodyContent(markdown)
        let html = MarkdownRenderer.wrapInHTMLDocument(bodyContent, theme: theme)

        // Present save panel first
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = suggestedName
        savePanel.canCreateDirectories = true
        savePanel.title = "Export PDF"
        savePanel.message = "Choose where to save the PDF file"

        let response = await savePanel.beginSheetModal(for: NSApp.keyWindow!)

        guard response == .OK, let url = savePanel.url else {
            throw ExportError.cancelled
        }

        // Create a temporary WebView sized to the page content width
        let contentWidth = pageWidth - pageMargin * 2
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: 1))
        webView.loadHTMLString(html, baseURL: nil)

        // Wait for the WebView to finish loading
        try await waitForWebViewToLoad(webView)

        // Get the full content height from the rendered document
        let contentHeight = try await getContentHeight(webView)

        // Resize the webview to fit all content
        webView.setFrameSize(NSSize(width: contentWidth, height: contentHeight))

        // Small delay to let the webview relayout at the new size
        try await Task.sleep(for: .milliseconds(100))

        // Generate PDF - the rect covers the full content
        let pdfData = try await generatePDF(from: webView)

        // Write PDF data to file
        try pdfData.write(to: url)

        return url
    }

    /// Gets the full content height of the rendered page via JavaScript
    private func getContentHeight(_ webView: WKWebView) async throws -> CGFloat {
        let height = try await webView.evaluateJavaScript("document.documentElement.scrollHeight") as? CGFloat ?? 1000
        return height
    }

    /// Generates PDF data from a rendered WebView
    private func generatePDF(from webView: WKWebView) async throws -> Data {
        let configuration = WKPDFConfiguration()
        configuration.rect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        return try await webView.pdf(configuration: configuration)
    }

    /// Waits for the WebView to finish loading its content
    private func waitForWebViewToLoad(_ webView: WKWebView) async throws {
        try await Task.sleep(for: .milliseconds(100))

        let readyState = try await webView.evaluateJavaScript("document.readyState") as? String
        if readyState != "complete" {
            try await Task.sleep(for: .milliseconds(300))
        }

        // Additional wait for rendering to complete
        try await Task.sleep(for: .milliseconds(200))
    }
}

