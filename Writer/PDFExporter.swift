//
//  PDFExporter.swift
//  Writer
//
//  Uses NSPrintOperation (WebKit's actual print pipeline) for proper
//  multi-page pagination, @media print CSS support, and page breaks.
//

import AppKit
import WebKit
import UniformTypeIdentifiers

/// Exports markdown content as a paginated PDF using WebKit's print pipeline.
///
/// `WKWebView.createPDF` renders the web content as a single continuous page.
/// For real multi-page output with page breaks, we must use `NSPrintOperation`,
/// which is the same path as ⌘P → "Save as PDF" and fully respects
/// `@media print` CSS, `page-break-*`, and `@page` rules.
class PDFExporter: NSObject, WKNavigationDelegate, @unchecked Sendable {
    // MARK: - Configuration

    /// US Letter page size in points (72 dpi)
    private static let letterSize = NSSize(width: 612, height: 792)

    // MARK: - State

    /// Retained so ARC doesn't deallocate the view mid-render
    private var webView: WKWebView?

    /// Bridges the delegate callback → async/await
    private var continuation: CheckedContinuation<Data, Error>?

    /// Temp file where NSPrintOperation writes the PDF
    private var tempURL: URL?

    // MARK: - Public API

    let markdown: String
    let theme: PreviewTheme

    init(markdown: String, theme: PreviewTheme) {
        self.markdown = markdown
        self.theme = theme
    }

    /// Renders the current markdown to paginated PDF data.
    func generatePDF() async throws -> Data {
        let bodyContent = MarkdownRenderer.renderBodyContent(markdown)
        let html = MarkdownRenderer.wrapInHTMLDocument(bodyContent, theme: theme)

        // Frame width determines the content layout width for print.
        // Height doesn't matter much — NSPrintOperation paginates based on paper size.
        let wv = WKWebView(frame: CGRect(origin: .zero, size: Self.letterSize))

        // Force light appearance so PDFs are always black-on-white
        wv.appearance = NSAppearance(named: .aqua)
        wv.navigationDelegate = self
        self.webView = wv

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            wv.loadHTMLString(html, baseURL: nil)
        }
    }

    /// Presents a save panel and writes the PDF to the chosen location.
    func save(suggestedName: String = "document.pdf") async throws -> URL {
        let pdfData = try await generatePDF()

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = suggestedName
        savePanel.canCreateDirectories = true
        savePanel.title = "Export PDF"
        savePanel.message = "Choose where to save the PDF file"

        let response: NSApplication.ModalResponse
        if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first {
            response = await savePanel.beginSheetModal(for: window)
        } else {
            response = await savePanel.begin()
        }

        guard response == .OK, let url = savePanel.url else {
            throw ExportError.cancelled
        }

        try pdfData.write(to: url)
        return url
    }

    // MARK: - WKNavigationDelegate

    /// Called when the HTML has fully loaded — now safe to print.
    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.printToPDF(webView: webView)
        }
    }

    /// Called if the HTML fails to load.
    nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
            self.webView = nil
        }
    }

    /// Called if the HTML fails to even start loading.
    nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(throwing: error)
            self.continuation = nil
            self.webView = nil
        }
    }

    // MARK: - Print Pipeline

    /// Uses NSPrintOperation to produce a properly paginated PDF.
    private func printToPDF(webView: WKWebView) {
        // Configure print settings
        let printInfo = NSPrintInfo()
        printInfo.paperSize = Self.letterSize
        printInfo.topMargin = 72      // 1 inch
        printInfo.bottomMargin = 72
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        printInfo.isHorizontallyCentered = false
        printInfo.isVerticallyCentered = false

        // Direct output to a temporary file instead of a physical printer
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("pdf")
        self.tempURL = tempFile

        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = tempFile

        // Get a print operation from WebKit — this is the same pipeline as ⌘P
        let printOp = webView.printOperation(with: printInfo)
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false

        // Run the print operation. With panels hidden, this is synchronous.
        printOp.runModal(
            for: NSWindow(),               // offscreen host window
            delegate: self,
            didRun: #selector(printOperationDidRun(_:success:contextInfo:)),
            contextInfo: nil
        )
    }

    /// Completion callback from NSPrintOperation.
    @objc private func printOperationDidRun(
        _ printOperation: NSPrintOperation,
        success: Bool,
        contextInfo: UnsafeMutableRawPointer?
    ) {
        defer {
            self.continuation = nil
            self.webView = nil
        }

        guard success, let tempURL = self.tempURL else {
            self.continuation?.resume(throwing: ExportError.writeFailed(
                NSError(domain: "PDFExport", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Print operation failed"])
            ))
            return
        }

        do {
            let pdfData = try Data(contentsOf: tempURL)
            try? FileManager.default.removeItem(at: tempURL)
            self.continuation?.resume(returning: pdfData)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            self.continuation?.resume(throwing: error)
        }
    }
}
