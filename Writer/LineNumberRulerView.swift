//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//  LineNumberRulerView.swift
//  Writer
//

import AppKit

/// A code-editor style gutter that draws line numbers alongside an `NSTextView`.
///
/// Numbers track logical (paragraph) lines: wrapped soft lines share the number
/// of the line they belong to, matching the behaviour of typical code editors.
final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    /// Horizontal padding on either side of the digits.
    private static let horizontalPadding: CGFloat = 8

    init(textView: NSTextView) {
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.textView = textView
        self.clientView = textView
        ruleThickness = 44

        // Redraw when the document changes or the user scrolls.
        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(invalidate),
            name: NSText.didChangeNotification, object: textView)
        if let contentView = scrollView?.contentView {
            contentView.postsBoundsChangedNotifications = true
            center.addObserver(
                self, selector: #selector(invalidate),
                name: NSView.boundsDidChangeNotification, object: contentView)
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func invalidate() {
        needsDisplay = true
    }

    /// 1-based logical line number for `characterIndex` (counts preceding newlines).
    static func lineNumber(forCharacterIndex characterIndex: Int, in string: NSString) -> Int {
        guard characterIndex > 0 else { return 1 }
        var lineNumber = 1
        string.enumerateSubstrings(
            in: NSRange(location: 0, length: min(characterIndex, string.length)),
            options: [.byLines, .substringNotRequired]
        ) { _, substringRange, enclosingRange, _ in
            // Count a line break only when the substring is actually terminated
            // by a line separator that falls at/before `characterIndex`.
            let hasTerminator = NSMaxRange(enclosingRange) > NSMaxRange(substringRange)
            if hasTerminator && NSMaxRange(enclosingRange) <= characterIndex {
                lineNumber += 1
            }
        }
        return lineNumber
    }

    private var digitAttributes: [NSAttributedString.Key: Any] {
        let size = (textView?.font?.pointSize ?? 13) * 0.85
        return [
            .font: NSFont.monospacedDigitSystemFont(ofSize: size, weight: .regular),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView,
            let layoutManager = textView.layoutManager,
            let textContainer = textView.textContainer
        else { return }

        let content = textView.string as NSString
        let insetHeight = textView.textContainerInset.height
        // Offset between text view and ruler coordinates (accounts for scrolling).
        let yOffset = convert(NSPoint.zero, from: textView).y
        let attributes = digitAttributes

        let visibleGlyphRange = layoutManager.glyphRange(
            forBoundingRect: textView.visibleRect, in: textContainer)

        var glyphIndex = visibleGlyphRange.location
        var pendingLineNumber: Int?

        while glyphIndex < NSMaxRange(visibleGlyphRange) {
            var fragmentRange = NSRange()
            let fragmentRect = layoutManager.lineFragmentRect(
                forGlyphAt: glyphIndex, effectiveRange: &fragmentRange)
            let charIndex = layoutManager.characterIndexForGlyph(at: fragmentRange.location)
            let lineRange = content.lineRange(for: NSRange(location: charIndex, length: 0))

            // Only the first fragment of a logical line gets a number.
            if charIndex == lineRange.location {
                let lineNumber = pendingLineNumber.map { $0 + 1 }
                    ?? Self.lineNumber(forCharacterIndex: charIndex, in: content)
                pendingLineNumber = lineNumber
                drawNumber(lineNumber, atY: fragmentRect.minY + insetHeight + yOffset, attributes: attributes)
            }

            glyphIndex = NSMaxRange(fragmentRange)
        }

        // Trailing empty line (document ends with a newline or is empty).
        if layoutManager.extraLineFragmentTextContainer != nil {
            let lineNumber = (pendingLineNumber ?? 0) + 1
            drawNumber(
                lineNumber,
                atY: layoutManager.extraLineFragmentRect.minY + insetHeight + yOffset,
                attributes: attributes)
        }
    }

    private func drawNumber(_ number: Int, atY y: CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let label = "\(number)" as NSString
        let size = label.size(withAttributes: attributes)
        let x = ruleThickness - size.width - Self.horizontalPadding
        label.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
    }
}
