//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
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

        textView.applyBaseTypingAttributes()

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


    // Cached regexes to avoid recompilation on every text change
    private static let headingRegex = try? NSRegularExpression(
        pattern: "^#{1,6}\\s.*$",
        options: [.anchorsMatchLines]
    )
    private static let boldItalicRegex = try? NSRegularExpression(
        pattern: "(\\*\\*\\*|___)(?=[^\\s*_\\n])(.+?)(?<=[^\\s*_\\n])\\1",
        options: []
    )
    private static let boldRegex = try? NSRegularExpression(
        pattern: "(?<!\\*)(\\*\\*(?=[^\\s*\\n])(.+?)(?<=[^\\s*\\n])\\*\\*(?!\\*)|(?<!_)__(?=[^\\s_\\n])(.+?)(?<=[^\\s_\\n])__(?!_))",
        options: []
    )
    private static let italicRegex = try? NSRegularExpression(
        pattern: "(?<!\\*)(\\*(?=[^\\s*\\n])(.+?)(?<=[^\\s*\\n])\\*(?!\\*)|(?<!_)_(?=[^\\s_\\n])(.+?)(?<=[^\\s_\\n])_(?!_))",
        options: []
    )
    private static let strikethroughRegex = try? NSRegularExpression(
        pattern: "~~(?=[^\\s~\\n])(.+?)(?<=[^\\s~\\n])~~",
        options: []
    )
    private static let highlightRegex = try? NSRegularExpression(
        pattern: "==(?=[^\\s=\\n])(.+?)(?<=[^\\s=\\n])==",
        options: []
    )

    override func insertNewline(_ sender: Any?) {
        super.insertNewline(sender)
        applyBaseTypingAttributes()
    }

    override func didChangeText() {
        super.didChangeText()
        if !isApplyingStyling {
            // Reset typing attributes immediately to prevent bold inheritance at heading boundaries
            applyBaseTypingAttributes()
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
        let baseParagraphStyle = baseParagraphStyle(for: baseFont)
        textStorage.removeAttribute(.foregroundColor, range: fullRange)
        textStorage.removeAttribute(.font, range: fullRange)
        textStorage.removeAttribute(.backgroundColor, range: fullRange)
        textStorage.removeAttribute(.strikethroughStyle, range: fullRange)
        textStorage.removeAttribute(.paragraphStyle, range: fullRange)
        textStorage.addAttribute(.font, value: baseFont, range: fullRange)
        textStorage.addAttribute(.paragraphStyle, value: baseParagraphStyle, range: fullRange)

        // Apply heading styles (# Heading)
        applyHeadingStyles(
            to: textStorage,
            text: text,
            baseFont: baseFont,
            baseParagraphStyle: baseParagraphStyle
        )

        // Apply bold-italic styles (***bolditalic*** or ___bolditalic___)
        applyBoldItalicStyles(to: textStorage, text: text, baseFont: baseFont)

        // Apply bold styles (**bold** or __bold__)
        applyBoldStyles(to: textStorage, text: text, baseFont: baseFont)

        // Apply italic styles (*italic* or _italic_)
        applyItalicStyles(to: textStorage, text: text, baseFont: baseFont)

        // Apply strikethrough styles (~~strikethrough~~)
        applyStrikethroughStyles(to: textStorage, text: text)

        // Apply highlight styles (==highlight==)
        applyHighlightStyles(to: textStorage, text: text)

        applyBaseTypingAttributes()
    }

    private func applyHeadingStyles(
        to textStorage: NSTextStorage,
        text: String,
        baseFont: NSFont,
        baseParagraphStyle: NSParagraphStyle
    ) {
        guard let regex = Self.headingRegex else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        let nsText = text as NSString
        let boldFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold)
        let bodyTextHeadIndent = baseParagraphStyle.headIndent
        let spaceWidth = bodyTextHeadIndent / 4

        for match in matches {
            let paragraphRange = nsText.paragraphRange(for: match.range)
            let headingLevel = headingLevel(for: match.range, in: nsText)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.setParagraphStyle(baseParagraphStyle)
            paragraphStyle.headIndent = bodyTextHeadIndent
            paragraphStyle.firstLineHeadIndent = headingMarkerFirstLineHeadIndent(
                for: headingLevel,
                bodyTextHeadIndent: bodyTextHeadIndent,
                spaceWidth: spaceWidth
            )

            textStorage.addAttribute(.font, value: boldFont, range: match.range)
            textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)
        }
    }

    private func headingLevel(for range: NSRange, in text: NSString) -> Int {
        let line = text.substring(with: range)
        return line.prefix(while: { $0 == "#" }).count
    }

    private func headingMarkerFirstLineHeadIndent(
        for level: Int,
        bodyTextHeadIndent: CGFloat,
        spaceWidth: CGFloat
    ) -> CGFloat {
        switch level {
        case 1:
            return bodyTextHeadIndent - (2 * spaceWidth)
        case 2:
            return bodyTextHeadIndent - (3 * spaceWidth)
        case 3...6:
            return bodyTextHeadIndent - (4 * spaceWidth)
        default:
            return 0
        }
    }

    private func baseParagraphStyle(for font: NSFont) -> NSMutableParagraphStyle {
        let spaceWidth = (" " as NSString).size(withAttributes: [.font: font]).width
        let bodyTextHeadIndent = 4 * spaceWidth
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.headIndent = bodyTextHeadIndent
        paragraphStyle.firstLineHeadIndent = bodyTextHeadIndent
        return paragraphStyle
    }

    func applyBaseTypingAttributes() {
        let baseFont = font ?? NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        let paragraphStyle = baseParagraphStyle(for: baseFont)
        defaultParagraphStyle = paragraphStyle
        typingAttributes[.font] = baseFont
        typingAttributes[.paragraphStyle] = paragraphStyle
    }

    private func applyBoldItalicStyles(to textStorage: NSTextStorage, text: String, baseFont: NSFont) {
        guard let regex = Self.boldItalicRegex else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        for match in matches {
            let boldDesc = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold).fontDescriptor
            let boldItalicDesc = boldDesc.withSymbolicTraits([.bold, .italic])
            let boldItalicFont = NSFont(descriptor: boldItalicDesc, size: baseFont.pointSize)
                ?? NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold)
            textStorage.addAttribute(.font, value: boldItalicFont, range: match.range)
        }
    }

    private func applyBoldStyles(to textStorage: NSTextStorage, text: String, baseFont: NSFont) {
        guard let regex = Self.boldRegex else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        for match in matches {
            // Skip ranges already styled as bold-italic
            let currentFont = textStorage.attribute(.font, at: match.range.location, effectiveRange: nil) as? NSFont
            if let traits = currentFont?.fontDescriptor.symbolicTraits,
               traits.contains(.bold) && traits.contains(.italic) {
                continue
            }

            let boldFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold)
            textStorage.addAttribute(.font, value: boldFont, range: match.range)
        }
    }

    private func applyItalicStyles(to textStorage: NSTextStorage, text: String, baseFont: NSFont) {
        guard let regex = Self.italicRegex else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        for match in matches {
            // Check if this range overlaps with bold or bold-italic - if so, skip
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

    private func applyStrikethroughStyles(to textStorage: NSTextStorage, text: String) {
        guard let regex = Self.strikethroughRegex else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        for match in matches {
            textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
            textStorage.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: match.range)
        }
    }

    private func applyHighlightStyles(to textStorage: NSTextStorage, text: String) {
        guard let regex = Self.highlightRegex else { return }

        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))

        let highlightColor = NSColor.systemYellow.withAlphaComponent(0.3)

        for match in matches {
            textStorage.addAttribute(.backgroundColor, value: highlightColor, range: match.range)
        }
    }
}
