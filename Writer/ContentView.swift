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
