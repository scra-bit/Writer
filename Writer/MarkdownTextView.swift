//
//  MarkdownTextView.swift
//  Writer
//

import SwiftUI
import AppKit

struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat = 16

    func makeNSView(context: Context) -> NSScrollView {
        // Create scroll view manually with custom text view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = MarkdownTextViewInternal()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.delegate = context.coordinator

        // Use system monospaced font
        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textContainerInset = NSSize(width: 24, height: 12)
        textView.textContainer?.lineFragmentPadding = 0

        // Set default paragraph style with line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        textView.defaultParagraphStyle = paragraphStyle

        // Set the text view as the document view
        scrollView.documentView = textView

        // Set initial text
        textView.string = text
        textView.applyMarkdownStyling()

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? MarkdownTextViewInternal else { return }

        // Only update if text changed from outside (not from typing)
        if textView.string != text {
            let selectedRange = textView.selectedRange()
            textView.string = text
            textView.applyMarkdownStyling()
            textView.setSelectedRange(selectedRange)
        }

        // Update font size if changed
        if abs(textView.font?.pointSize ?? 0 - fontSize) > 0.1 {
            textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            textView.applyMarkdownStyling()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextView

        init(_ parent: MarkdownTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? MarkdownTextViewInternal else { return }
            parent.text = textView.string
        }
    }
}

// MARK: - Custom Text View with Syntax Highlighting

class MarkdownTextViewInternal: NSTextView {
    private var isApplyingStyling = false

    override func didChangeText() {
        super.didChangeText()
        if !isApplyingStyling {
            applyMarkdownStyling()
        }
    }

    func applyMarkdownStyling() {
        isApplyingStyling = true
        defer { isApplyingStyling = false }

        guard let textStorage = textStorage else { return }

        let fullRange = NSRange(location: 0, length: textStorage.length)
        let text = textStorage.string

        // Reset to default attributes
        let baseFont = font ?? NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.removeAttribute(.font, range: fullRange)
        textStorage.removeAttribute(.backgroundColor, range: fullRange)
        textStorage.addAttribute(.font, value: baseFont, range: fullRange)

        // Apply heading styles (# Heading)
        applyHeadingStyles(to: textStorage, text: text, baseFont: baseFont)

        // Apply bold styles (**bold** or __bold__)
        applyBoldStyles(to: textStorage, text: text, baseFont: baseFont)

        // Apply italic styles (*italic* or _italic_)
        applyItalicStyles(to: textStorage, text: text, baseFont: baseFont)

        // Apply highlight styles (==highlight==)
        applyHighlightStyles(to: textStorage, text: text)
    }

    private func applyHeadingStyles(to textStorage: NSTextStorage, text: String, baseFont: NSFont) {
        let headingPattern = "^#{1,6}\\s+.+$"
        guard let regex = try? NSRegularExpression(pattern: headingPattern, options: [.anchorsMatchLines]) else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        for match in matches {
            let boldFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold)
            textStorage.addAttribute(.font, value: boldFont, range: match.range)
        }
    }

    private func applyBoldStyles(to textStorage: NSTextStorage, text: String, baseFont: NSFont) {
        // Pattern for **bold** or __bold__
        let boldPattern = "(\\*\\*|__)[^*_\\s][^*_]*?[^*_\\s](\\*\\*|__)"
        guard let regex = try? NSRegularExpression(pattern: boldPattern, options: []) else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        for match in matches {
            let boldFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold)
            textStorage.addAttribute(.font, value: boldFont, range: match.range)
        }
    }

    private func applyItalicStyles(to textStorage: NSTextStorage, text: String, baseFont: NSFont) {
        // Pattern for *italic* or _italic_ (but not ** or __)
        let italicPattern = "(?<!\\*)(\\*[^*_\\s][^*_]*?[^*_\\s]\\*|_[^_\\s][^_]*?[^_\\s]_)"
        guard let regex = try? NSRegularExpression(pattern: italicPattern, options: []) else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        for match in matches {
            // Check if this range overlaps with bold - if so, skip (bold takes precedence)
            let currentFont = textStorage.attribute(.font, at: match.range.location, effectiveRange: nil) as? NSFont
            if let currentFont = currentFont,
               currentFont.fontDescriptor.symbolicTraits.contains(.bold) {
                continue
            }

            // Apply italic
            if let italicFont = NSFont(descriptor: baseFont.fontDescriptor.withSymbolicTraits(.italic), size: baseFont.pointSize) {
                textStorage.addAttribute(.font, value: italicFont, range: match.range)
            }
        }
    }

    private func applyHighlightStyles(to textStorage: NSTextStorage, text: String) {
        // Pattern for ==highlight==
        let highlightPattern = "==[^=\\s][^=]*?[^=\\s]=="
        guard let regex = try? NSRegularExpression(pattern: highlightPattern, options: []) else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        let highlightColor = NSColor.systemYellow.withAlphaComponent(0.3)

        for match in matches {
            textStorage.addAttribute(.backgroundColor, value: highlightColor, range: match.range)
        }
    }
}
