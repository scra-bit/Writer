//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
import AppKit
import Foundation
import Markdown

struct MarkdownRenderContext {
    let documentURL: URL?
    let workspaceRootURL: URL?

    init(documentURL: URL? = nil, workspaceRootURL: URL? = nil) {
        self.documentURL = documentURL
        self.workspaceRootURL = workspaceRootURL
    }
}

struct ContentBlockSyntax {
    enum CaptionStyle {
        case doubleQuoted
        case singleQuoted
        case parenthesized
    }

    struct ContentBlockMatch {
        let path: String
        let caption: String?
        let captionStyle: CaptionStyle?
        let originalLine: String
    }

    struct ResolvedContentBlock {
        let match: ContentBlockMatch
        let url: URL?
    }

    static func parseLine(_ line: String) -> ContentBlockMatch? {
        let indentation = line.prefix(while: { $0 == " " })
        guard indentation.count <= 3 else {
            return nil
        }

        let trimmed = line.trimmingCharacters(in: .newlines)
        let candidate = trimmed.dropFirst(indentation.count)
        guard !candidate.isEmpty else {
            return nil
        }

        let parsedTitle = parseTitle(from: String(candidate))
        let pathPortion = parsedTitle?.pathPortion ?? String(candidate)
        let path = pathPortion.trimmingCharacters(in: .whitespaces)

        guard isValidPathOrURL(path) else {
            return nil
        }

        return ContentBlockMatch(
            path: path,
            caption: parsedTitle?.title,
            captionStyle: parsedTitle?.style,
            originalLine: line
        )
    }

    static func resolve(_ match: ContentBlockMatch, context: MarkdownRenderContext) -> ResolvedContentBlock {
        let normalizedPath = NSString(string: match.path).expandingTildeInPath
        let fileManager = FileManager.default

        if isOnlineImageURL(normalizedPath) || isAngleBracketImageURL(normalizedPath) {
            return ResolvedContentBlock(match: match, url: URL(string: stripAngleBrackets(from: normalizedPath)))
        }

        if normalizedPath.hasPrefix("/") {
            let absoluteURL = URL(fileURLWithPath: normalizedPath)
            return ResolvedContentBlock(match: match, url: fileManager.fileExists(atPath: absoluteURL.path) ? absoluteURL : nil)
        }

        let searchRoots = [context.documentURL?.deletingLastPathComponent(), context.workspaceRootURL].compactMap { $0 }
        for root in searchRoots {
            let candidate = root.appendingPathComponent(normalizedPath)
            if fileManager.fileExists(atPath: candidate.path) {
                return ResolvedContentBlock(match: match, url: candidate)
            }
        }

        return ResolvedContentBlock(match: match, url: nil)
    }

    private struct ParsedTitle {
        let pathPortion: String
        let title: String
        let style: CaptionStyle
    }

    private static func parseTitle(from candidate: String) -> ParsedTitle? {
        let trimmed = candidate.trimmingCharacters(in: .whitespaces)
        guard let lastCharacter = trimmed.last else {
            return nil
        }

        let variants: [(Character, Character, CaptionStyle)] = [
            ("\"", "\"", .doubleQuoted),
            ("'", "'", .singleQuoted),
            ("(", ")", .parenthesized),
        ]

        for (open, close, style) in variants where lastCharacter == close {
            guard let startIndex = findOpeningDelimiter(in: trimmed, open: open, close: close) else {
                continue
            }

            let titleStart = trimmed.index(after: startIndex)
            let titleEnd = trimmed.index(before: trimmed.endIndex)
            let title = String(trimmed[titleStart..<titleEnd])
            let pathPortion = String(trimmed[..<startIndex])

            guard !pathPortion.isEmpty, pathPortion.last?.isWhitespace == true else {
                continue
            }

            return ParsedTitle(
                pathPortion: pathPortion,
                title: unescapeTitle(title),
                style: style
            )
        }

        return nil
    }

    private static func findOpeningDelimiter(
        in value: String,
        open: Character,
        close: Character
    ) -> String.Index? {
        var depth = 0
        var index = value.index(before: value.endIndex)

        while true {
            let character = value[index]
            if character == close, !isEscaped(value, at: index) {
                depth += 1
            } else if character == open, !isEscaped(value, at: index) {
                depth -= 1
                if depth == 0 {
                    return index
                }
            }

            if index == value.startIndex {
                break
            }
            index = value.index(before: index)
        }

        return nil
    }

    private static func unescapeTitle(_ title: String) -> String {
        var result = ""
        var isEscaping = false

        for character in title {
            if isEscaping {
                result.append(character)
                isEscaping = false
            } else if character == "\\" {
                isEscaping = true
            } else {
                result.append(character)
            }
        }

        if isEscaping {
            result.append("\\")
        }

        return result
    }

    private static func isValidPathOrURL(_ path: String) -> Bool {
        guard !path.isEmpty else {
            return false
        }

        if isAngleBracketImageURL(path) || isOnlineImageURL(path) {
            return true
        }

        return isValidLocalFilePath(path)
    }

    private static func isValidLocalFilePath(_ path: String) -> Bool {
        guard path.hasPrefix("/") else {
            return false
        }

        let components = path.split(separator: "/", omittingEmptySubsequences: true)
        guard !components.isEmpty else {
            return false
        }

        for component in components {
            let value = String(component)
            guard !value.isEmpty, !value.contains("\t") else {
                return false
            }

            let extensionParts = value.split(separator: ".", omittingEmptySubsequences: false)
            if extensionParts.count > 1 {
                for extensionPart in extensionParts.dropFirst() where !extensionPart.isEmpty {
                    guard extensionPart.range(of: #"^[A-Za-z0-9]+$"#, options: .regularExpression) != nil else {
                        return false
                    }
                }
            }
        }

        return true
    }

    private static func isAngleBracketImageURL(_ value: String) -> Bool {
        guard value.first == "<", value.last == ">" else {
            return false
        }

        let inner = String(value.dropFirst().dropLast())
        guard !inner.contains(where: { $0.isWhitespace || $0 == "<" || $0 == ">" }) else {
            return false
        }

        return isOnlineImageURL(inner)
    }

    private static func isOnlineImageURL(_ value: String) -> Bool {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return false
        }

        let pathExtension = (url.path as NSString).pathExtension.lowercased()
        return ["png", "jpg", "jpeg", "gif", "tif", "tiff", "svg"].contains(pathExtension)
    }

    private static func stripAngleBrackets(from value: String) -> String {
        guard value.first == "<", value.last == ">" else {
            return value
        }
        return String(value.dropFirst().dropLast())
    }

    private static func isEscaped(_ value: String, at index: String.Index) -> Bool {
        guard index > value.startIndex else {
            return false
        }

        var backslashCount = 0
        var currentIndex = value.index(before: index)

        while value[currentIndex] == "\\" {
            backslashCount += 1
            guard currentIndex > value.startIndex else {
                break
            }
            currentIndex = value.index(before: currentIndex)
        }

        return backslashCount.isMultiple(of: 2) == false
    }
}

private enum ContentBlockKind {
    case transcludedMarkdown
    case code(language: String?)
    case table(delimiter: Character)
    case image(mimeType: String)
    case unsupported
}

private enum RenderSegment {
    case markdown(String)
    case contentBlock(ContentBlockSyntax.ResolvedContentBlock)
}

// Custom MarkupVisitor to generate HTML
struct HTMLVisitor: MarkupVisitor {
    typealias Result = String

    private func escapeText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func escapeAttribute(_ text: String) -> String {
        escapeText(text)
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    mutating func defaultVisit(_ markup: Markup) -> String {
        markup.children.map { $0.accept(&self) }.joined()
    }

    mutating func visitDocument(_ document: Document) -> String {
        document.children.map { $0.accept(&self) }.joined()
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        let level = heading.level
        let content = heading.children.map { $0.accept(&self) }.joined()
        return "<h\(level)>\(content)</h\(level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        let content = paragraph.children.map { $0.accept(&self) }.joined()
        return "<p>\(content)</p>\n"
    }

    mutating func visitText(_ text: Markdown.Text) -> String {
        escapeText(text.string)
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        let content = strong.children.map { $0.accept(&self) }.joined()
        return "<strong>\(content)</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        let content = strikethrough.children.map { $0.accept(&self) }.joined()
        return "<del>\(content)</del>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        let content = emphasis.children.map { $0.accept(&self) }.joined()
        return "<em>\(content)</em>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        "<code>\(escapeText(inlineCode.code))</code>"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let language = escapeAttribute(codeBlock.language ?? "")
        let code = escapeText(codeBlock.code)
        if language.isEmpty {
            return "<pre><code>\(code)</code></pre>\n"
        }
        return "<pre><code class=\"language-\(language)\">\(code)</code></pre>\n"
    }

    mutating func visitLink(_ link: Markdown.Link) -> String {
        let content = link.children.map { $0.accept(&self) }.joined()
        let destination = escapeAttribute(link.destination ?? "")
        return "<a href=\"\(destination)\">\(content)</a>"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        let content = blockQuote.children.map { $0.accept(&self) }.joined()
        return "<blockquote>\n\(content)</blockquote>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        let content = unorderedList.children.map { $0.accept(&self) }.joined()
        return "<ul>\n\(content)</ul>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let content = orderedList.children.map { $0.accept(&self) }.joined()
        return "<ol>\n\(content)</ol>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        let content = listItem.children.map { $0.accept(&self) }.joined()
        return "<li>\(content)</li>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        "<hr>\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        "\n"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        "<br>\n"
    }

    mutating func visitImage(_ image: Markdown.Image) -> String {
        let alt = image.children.map { $0.accept(&self) }.joined()
        let src = escapeAttribute(image.source ?? "")
        let title = escapeAttribute(image.title ?? "")
        if title.isEmpty {
            return "<img src=\"\(src)\" alt=\"\(alt)\">"
        }
        return "<img src=\"\(src)\" alt=\"\(alt)\" title=\"\(title)\">"
    }

    mutating func visitTable(_ table: Markdown.Table) -> String {
        let content = table.children.map { $0.accept(&self) }.joined()
        return "<table>\n\(content)</table>\n"
    }

    mutating func visitTableHead(_ tableHead: Markdown.Table.Head) -> String {
        let content = tableHead.children.map { $0.accept(&self) }.joined()
        return "<thead>\n<tr>\(content)</tr>\n</thead>\n"
    }

    mutating func visitTableBody(_ tableBody: Markdown.Table.Body) -> String {
        let content = tableBody.children.map { $0.accept(&self) }.joined()
        return "<tbody>\n\(content)</tbody>\n"
    }

    mutating func visitTableRow(_ tableRow: Markdown.Table.Row) -> String {
        let content = tableRow.children.map { $0.accept(&self) }.joined()
        return "<tr>\(content)</tr>\n"
    }

    mutating func visitTableCell(_ tableCell: Markdown.Table.Cell) -> String {
        let content = tableCell.children.map { $0.accept(&self) }.joined()
        return "<td>\(content)</td>"
    }
}

/// Renders markdown to HTML
struct MarkdownRenderer {
    private static nonisolated(unsafe) var _highlightRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "==(.+?)==", options: [])
    }()

    private static var highlightRegex: NSRegularExpression? {
        _highlightRegex
    }

    static func renderBodyContent(
        _ markdown: String,
        context: MarkdownRenderContext = MarkdownRenderContext()
    ) -> String {
        let initialVisited = context.documentURL.map { Set([ $0 ]) } ?? []
        return renderBodyContent(markdown, context: context, visitedURLs: initialVisited)
    }

    static func escapeHTMLEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    static func wrapInHTMLDocument(_ bodyContent: String, theme: PreviewTheme) -> String {
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

    @discardableResult
    func renderBodyContent(
        _ markdown: String,
        context: MarkdownRenderContext = MarkdownRenderContext()
    ) -> String {
        Self.renderBodyContent(markdown, context: context)
    }

    @discardableResult
    func escapeHTMLEntities(_ text: String) -> String {
        Self.escapeHTMLEntities(text)
    }

    @discardableResult
    func wrapInHTMLDocument(_ bodyContent: String, theme: PreviewTheme) -> String {
        Self.wrapInHTMLDocument(bodyContent, theme: theme)
    }

    private static func renderBodyContent(
        _ markdown: String,
        context: MarkdownRenderContext,
        visitedURLs: Set<URL>
    ) -> String {
        let segments = parseSegments(markdown, context: context)

        return segments.map { segment in
            switch segment {
            case .markdown(let markdownChunk):
                return renderMarkdownChunk(markdownChunk)
            case .contentBlock(let block):
                return renderContentBlock(block, context: context, visitedURLs: visitedURLs)
            }
        }.joined()
    }

    private static func parseSegments(
        _ markdown: String,
        context: MarkdownRenderContext
    ) -> [RenderSegment] {
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var segments: [RenderSegment] = []
        var markdownLines: [String] = []

        func flushMarkdown() {
            guard !markdownLines.isEmpty else { return }
            segments.append(.markdown(markdownLines.joined(separator: "\n")))
            markdownLines.removeAll(keepingCapacity: true)
        }

        for line in lines {
            if let match = ContentBlockSyntax.parseLine(line) {
                flushMarkdown()
                segments.append(.contentBlock(ContentBlockSyntax.resolve(match, context: context)))
            } else {
                markdownLines.append(line)
            }
        }

        flushMarkdown()
        return segments
    }

    private static func renderMarkdownChunk(_ markdown: String) -> String {
        guard !markdown.isEmpty else {
            return ""
        }

        let escaped = escapeHTMLEntities(markdown)
        let document = Document(parsing: escaped)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        return processHighlights(html)
    }

    private static func renderContentBlock(
        _ resolvedBlock: ContentBlockSyntax.ResolvedContentBlock,
        context: MarkdownRenderContext,
        visitedURLs: Set<URL>
    ) -> String {
        guard let url = resolvedBlock.url else {
            return renderWarningBlock(
                title: "Missing content block",
                detail: resolvedBlock.match.path,
                originalLine: resolvedBlock.match.originalLine
            )
        }

        if visitedURLs.contains(url) {
            return renderWarningBlock(
                title: "Recursive content block",
                detail: url.lastPathComponent,
                originalLine: resolvedBlock.match.originalLine
            )
        }

        switch classifyContentBlock(url: url) {
        case .transcludedMarkdown:
            return renderTranscludedTextBlock(url: url, resolvedBlock: resolvedBlock, context: context, visitedURLs: visitedURLs)
        case .code(let language):
            return renderCodeBlock(url: url, resolvedBlock: resolvedBlock, language: language)
        case .table(let delimiter):
            return renderTableBlock(url: url, resolvedBlock: resolvedBlock, delimiter: delimiter)
        case .image(let mimeType):
            return renderImageBlock(url: url, resolvedBlock: resolvedBlock, mimeType: mimeType)
        case .unsupported:
            return renderWarningBlock(
                title: "Unsupported content block",
                detail: url.lastPathComponent,
                originalLine: resolvedBlock.match.originalLine
            )
        }
    }

    private static func renderTranscludedTextBlock(
        url: URL,
        resolvedBlock: ContentBlockSyntax.ResolvedContentBlock,
        context: MarkdownRenderContext,
        visitedURLs: Set<URL>
    ) -> String {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return renderWarningBlock(
                title: "Unreadable content block",
                detail: url.lastPathComponent,
                originalLine: resolvedBlock.match.originalLine
            )
        }

        let nestedContext = MarkdownRenderContext(
            documentURL: url,
            workspaceRootURL: context.workspaceRootURL ?? context.documentURL?.deletingLastPathComponent()
        )
        let nestedHTML = renderBodyContent(contents, context: nestedContext, visitedURLs: visitedURLs.union([url]))

        return wrapContentBlock(
            type: "text",
            body: nestedHTML,
            caption: resolvedBlock.match.caption
        )
    }

    private static func renderCodeBlock(
        url: URL,
        resolvedBlock: ContentBlockSyntax.ResolvedContentBlock,
        language: String?
    ) -> String {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return renderWarningBlock(
                title: "Unreadable code block",
                detail: url.lastPathComponent,
                originalLine: resolvedBlock.match.originalLine
            )
        }

        let languageClass = language.map { " class=\"language-\(escapeAttribute($0))\"" } ?? ""
        let codeHTML = "<pre><code\(languageClass)>\(escapeHTMLEntities(contents))</code></pre>"
        return wrapContentBlock(type: "code", body: codeHTML, caption: resolvedBlock.match.caption)
    }

    private static func renderTableBlock(
        url: URL,
        resolvedBlock: ContentBlockSyntax.ResolvedContentBlock,
        delimiter: Character
    ) -> String {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return renderWarningBlock(
                title: "Unreadable table block",
                detail: url.lastPathComponent,
                originalLine: resolvedBlock.match.originalLine
            )
        }

        let rows = parseDelimitedRows(contents, delimiter: delimiter)
        guard let header = rows.first, !header.isEmpty else {
            return renderWarningBlock(
                title: "Empty table block",
                detail: url.lastPathComponent,
                originalLine: resolvedBlock.match.originalLine
            )
        }

        let bodyRows = rows.dropFirst()
        let headerHTML = header.map { "<th>\(escapeHTMLEntities($0))</th>" }.joined()
        let bodyHTML = bodyRows.map { row in
            let normalizedRow = normalizeRow(row, to: header.count)
            let cells = normalizedRow.map { "<td>\(escapeHTMLEntities($0))</td>" }.joined()
            return "<tr>\(cells)</tr>"
        }.joined(separator: "\n")

        let tableHTML = """
        <table>
        <thead><tr>\(headerHTML)</tr></thead>
        <tbody>
        \(bodyHTML)
        </tbody>
        </table>
        """

        return wrapContentBlock(type: "table", body: tableHTML, caption: resolvedBlock.match.caption)
    }

    private static func renderImageBlock(
        url: URL,
        resolvedBlock: ContentBlockSyntax.ResolvedContentBlock,
        mimeType: String
    ) -> String {
        guard let data = try? Data(contentsOf: url) else {
            return renderWarningBlock(
                title: "Unreadable image block",
                detail: url.lastPathComponent,
                originalLine: resolvedBlock.match.originalLine
            )
        }

        let altText = escapeAttribute(resolvedBlock.match.caption ?? url.deletingPathExtension().lastPathComponent)
        let base64 = data.base64EncodedString()
        let body = "<img src=\"data:\(mimeType);base64,\(base64)\" alt=\"\(altText)\">"
        return wrapContentBlock(type: "image", body: body, caption: resolvedBlock.match.caption)
    }

    private static func renderWarningBlock(title: String, detail: String, originalLine: String) -> String {
        """
        <div class="content-block content-block-warning">
            <p><strong>\(escapeHTMLEntities(title)):</strong> \(escapeHTMLEntities(detail))</p>
            <pre><code>\(escapeHTMLEntities(originalLine))</code></pre>
        </div>
        """
    }

    private static func wrapContentBlock(type: String, body: String, caption: String?) -> String {
        let captionHTML = caption.map {
            "\n<figcaption class=\"content-block-caption\">\(escapeHTMLEntities($0))</figcaption>"
        } ?? ""

        return """
        <figure class="content-block content-block-\(type)">
        \(body)\(captionHTML)
        </figure>
        """
    }

    private static func classifyContentBlock(url: URL) -> ContentBlockKind {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "md", "markdown", "txt":
            return .transcludedMarkdown
        case "csv":
            return .table(delimiter: ",")
        case "tsv":
            return .table(delimiter: "\t")
        case "png":
            return .image(mimeType: "image/png")
        case "jpg", "jpeg":
            return .image(mimeType: "image/jpeg")
        case "gif":
            return .image(mimeType: "image/gif")
        case "webp":
            return .image(mimeType: "image/webp")
        case "svg":
            return .image(mimeType: "image/svg+xml")
        case "heic":
            return .image(mimeType: "image/heic")
        case "heif":
            return .image(mimeType: "image/heif")
        case "tif", "tiff":
            return .image(mimeType: "image/tiff")
        default:
            if codeExtensions.contains(ext) {
                return .code(language: ext.isEmpty ? nil : ext)
            }
            return .unsupported
        }
    }

    private static let codeExtensions: Set<String> = [
        "c", "cc", "cpp", "css", "go", "h", "hpp", "html", "java", "js", "json", "kt",
        "m", "mm", "php", "py", "rb", "rs", "sh", "sql", "swift", "ts", "tsx", "xml",
        "yaml", "yml", "zsh"
    ]

    private static func parseDelimitedRows(_ text: String, delimiter: Character) -> [[String]] {
        text
            .split(whereSeparator: \.isNewline)
            .map { parseDelimitedRow(String($0), delimiter: delimiter) }
            .filter { !$0.isEmpty }
    }

    private static func parseDelimitedRow(_ row: String, delimiter: Character) -> [String] {
        var cells: [String] = []
        var current = ""
        var isInsideQuotes = false
        var index = row.startIndex

        while index < row.endIndex {
            let character = row[index]

            if character == "\"" {
                let nextIndex = row.index(after: index)
                if isInsideQuotes, nextIndex < row.endIndex, row[nextIndex] == "\"" {
                    current.append("\"")
                    index = row.index(after: nextIndex)
                    continue
                }
                isInsideQuotes.toggle()
            } else if character == delimiter, !isInsideQuotes {
                cells.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(character)
            }

            index = row.index(after: index)
        }

        cells.append(current.trimmingCharacters(in: .whitespaces))
        return cells
    }

    private static func normalizeRow(_ row: [String], to count: Int) -> [String] {
        if row.count == count {
            return row
        }
        if row.count > count {
            return Array(row.prefix(count))
        }
        return row + Array(repeating: "", count: count - row.count)
    }

    private static func escapeAttribute(_ text: String) -> String {
        escapeHTMLEntities(text)
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func processHighlights(_ text: String) -> String {
        guard let regex = highlightRegex else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "<mark class=\"highlight\">$1</mark>"
        )
    }
}
