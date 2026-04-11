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
        let renderer = MarkdownRenderer()
        let bodyContent = renderer.renderBodyContent(markdown)
        let html = renderer.wrapInHTMLDocument(bodyContent, theme: theme)
        webView.loadHTMLString(html, baseURL: nil)
    }
}
