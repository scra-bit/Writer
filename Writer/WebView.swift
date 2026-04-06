import SwiftUI
import WebKit
import Observation
import Markdown

struct WebView: View {
    let markdown: String
    let theme: PreviewTheme
    @Environment(ThemeStore.self) private var themeStore
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WebViewRepresentable(markdown: markdown, theme: themeStore.previewTheme)
        }
        .overlay(alignment: .bottomTrailing) {
            Menu {
                ForEach(PreviewTheme.allThemes, id: \.name) { themeOption in
                    Button(themeOption.name) {
                        themeStore.previewTheme = themeOption
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "paintbrush")
                        .font(.system(size: 12))
                    Text(themeStore.previewTheme.name)
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .menuStyle(.borderlessButton)
            .padding(.trailing, 6)
            .padding(.bottom, 6)
        }
    }
}

struct WebViewRepresentable: NSViewRepresentable {
    let markdown: String
    let theme: PreviewTheme
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(NSColor.white, forKey: "backgroundColor")
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        let html = renderMarkdownToHTML(markdown)
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    private func renderMarkdownToHTML(_ markdown: String) -> String {
        let bodyContent = renderBodyContent(markdown)
        return wrapInHTMLDocument(bodyContent)
    }
    
    private func renderBodyContent(_ markdown: String) -> String {
        let escaped = escapeHTMLEntities(markdown)
        
        let document = Document(parsing: escaped)
        var visitor = HTMLVisitor()
        var html = document.accept(&visitor)
        
        // Process custom ==highlight== syntax
        html = processHighlights(html)
        
        return html
    }
    
    private func escapeHTMLEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
    
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

// Custom MarkupVisitor to generate HTML
struct HTMLVisitor: MarkupVisitor {
    typealias Result = String
    
    mutating func defaultVisit(_ markup: Markup) -> String {
        return markup.children.map { $0.accept(&self) }.joined()
    }
    
    mutating func visitDocument(_ document: Document) -> String {
        return document.children.map { $0.accept(&self) }.joined()
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
        return text.string
    }
    
    mutating func visitStrong(_ strong: Strong) -> String {
        let content = strong.children.map { $0.accept(&self) }.joined()
        return "<strong>\(content)</strong>"
    }
    
    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        let content = emphasis.children.map { $0.accept(&self) }.joined()
        return "<em>\(content)</em>"
    }
    
    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        return "<code>\(inlineCode.code)</code>"
    }
    
    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let language = codeBlock.language ?? ""
        let code = codeBlock.code
        if language.isEmpty {
            return "<pre><code>\(code)</code></pre>\n"
        }
        return "<pre><code class=\"language-\(language)\">\(code)</code></pre>\n"
    }
    
    mutating func visitLink(_ link: Markdown.Link) -> String {
        let content = link.children.map { $0.accept(&self) }.joined()
        let destination = link.destination ?? ""
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
        return "<hr>\n"
    }
    
    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        return "\n"
    }
    
    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        return "<br>\n"
    }
    
    mutating func visitImage(_ image: Markdown.Image) -> String {
        let alt = image.children.map { $0.accept(&self) }.joined()
        let src = image.source ?? ""
        let title = image.title ?? ""
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
