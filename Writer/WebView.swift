import SwiftUI
import WebKit
import Observation

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
        var html = markdown
        html = escapeHTMLEntities(html)
        html = processCodeBlocks(html)
        html = processInlineCode(html)
        html = processBoldAndItalic(html)
        html = processLinks(html)
        html = processHeaders(html)
        html = processBlockquotes(html)
        html = processLists(html)
        html = processHorizontalRules(html)
        html = wrapParagraphs(html)
        return html
    }
    
    private func escapeHTMLEntities(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
    
    private func processCodeBlocks(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "```([\\s\\S]*?)```", options: []) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "<pre><code>$1</code></pre>"
        )
    }
    
    private func processInlineCode(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "`([^`]+)`", options: []) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "<code>$1</code>"
        )
    }
    
    private func processBoldAndItalic(_ text: String) -> String {
        var result = text
        
        // Bold + Italic: ***text***
        if let regex = try? NSRegularExpression(pattern: "\\*\\*\\*(.+?)\\*\\*\\*", options: []) {
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "<strong><em>$1</em></strong>"
            )
        }
        
        // Bold: **text**
        if let regex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*", options: []) {
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "<strong>$1</strong>"
            )
        }
        
        // Italic: *text* (but not already processed bold)
        if let regex = try? NSRegularExpression(pattern: "\\*(.+?)\\*", options: []) {
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "<em>$1</em>"
            )
        }
        
        return result
    }
    
    private func processLinks(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)", options: []) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "<a href=\"$2\">$1</a>"
        )
    }
    
    private func processHeaders(_ text: String) -> String {
        var result = text
        let headerPatterns = [
            ("^######\\s+(.+)$", "<h6>$1</h6>"),
            ("^#####\\s+(.+)$", "<h5>$1</h5>"),
            ("^####\\s+(.+)$", "<h4>$1</h4>"),
            ("^###\\s+(.+)$", "<h3>$1</h3>"),
            ("^##\\s+(.+)$", "<h2>$1</h2>"),
            ("^#\\s+(.+)$", "<h1>$1</h1>")
        ]
        
        for (pattern, replacement) in headerPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines) else {
                continue
            }
            result = regex.stringByReplacingMatches(
                in: result,
                options: [],
                range: NSRange(result.startIndex..., in: result),
                withTemplate: replacement
            )
        }
        
        return result
    }
    
    private func processBlockquotes(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "^&gt;\\s*(.+)$", options: .anchorsMatchLines) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "<blockquote>$1</blockquote>"
        )
    }
    
    private func processLists(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "^[-*+]\\s+(.+)$", options: .anchorsMatchLines) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "<li>$1</li>"
        )
    }
    
    private func processHorizontalRules(_ text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "^---+$", options: .anchorsMatchLines) else {
            return text
        }
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..., in: text),
            withTemplate: "<hr>"
        )
    }
    
    private func wrapParagraphs(_ text: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var inList = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            guard !trimmed.isEmpty else {
                if inList {
                    result.append("</ul>")
                    inList = false
                }
                continue
            }
            
            let isBlockElement = trimmed.hasPrefix("<h") ||
                                trimmed.hasPrefix("<pre") ||
                                trimmed.hasPrefix("<blockquote") ||
                                trimmed.hasPrefix("<hr")
            
            if trimmed.hasPrefix("<li>") {
                if !inList {
                    result.append("<ul>")
                    inList = true
                }
                result.append(line)
            } else if isBlockElement {
                if inList {
                    result.append("</ul>")
                    inList = false
                }
                result.append(trimmed)
            } else {
                if inList {
                    result.append("</ul>")
                    inList = false
                }
                result.append("<p>\(trimmed)</p>")
            }
        }
        
        if inList {
            result.append("</ul>")
        }
        
        return result.joined(separator: "\n")
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
