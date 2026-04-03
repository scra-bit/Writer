//
//  ContentView.swift
//  Writer
//

import SwiftUI

struct ContentView: View {
    @Binding var document: TextDocument
    @State private var showPreview = true
    @Environment(ThemeStore.self) private var themeStore

    var body: some View {
        Group {
            if showPreview {
                HSplitView {
                    editorView
                        .frame(minWidth: 200)
                    WebView(markdown: document.text, theme: themeStore.previewTheme)
                        .frame(minWidth: 200)
                }
            } else {
                editorView
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { showPreview.toggle() }) {
                    Image(systemName: showPreview ? "sidebar.left" : "sidebar.right")
                }
                .help(showPreview ? "Hide Preview" : "Show Preview")
            }
        }
    }

    private var editorView: some View {
        TextEditor(text: $document.text)
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentViewPreview()
}

private struct ContentViewPreview: View {
    @State private var document = TextDocument(
        text: """
        # Writer Preview

        This is a sample document for the canvas.

        - Edit text on the left
        - Inspect the rendered preview on the right
        """
    )
    @State private var themeStore = ThemeStore()

    var body: some View {
        ContentView(document: $document)
            .environment(themeStore)
            .frame(width: 900, height: 600)
    }
}
