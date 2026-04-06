//
//  ContentView.swift
//  Writer
//

import SwiftUI

struct ContentView: View {
    @State private var showNewFileSheet = false
    @State private var newFileName = ""
    @Environment(EditorStore.self) private var editorStore
    @State private var showPreview = true
    @Environment(ThemeStore.self) private var themeStore

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            Group {
                if editorStore.selectedFileURL == nil {
                    emptyStateView
                } else if showPreview {
                    HSplitView {
                        editorView
                            .frame(minWidth: 280)
                        WebView(markdown: editorStore.documentText, theme: themeStore.previewTheme)
                            .frame(minWidth: 280)
                    }
                } else {
                    editorView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(editorStore.currentTitle)
        .onChange(of: editorStore.documentText) { _, _ in
            editorStore.scheduleAutosave()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { showPreview.toggle() }) {
                    Image(systemName: showPreview ? "sidebar.left" : "sidebar.right")
                }
                .help(showPreview ? "Hide Preview" : "Show Preview")
            }

            ToolbarItem {
                Button(action: { editorStore.persistCurrentDocument() }) {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Save")
                .disabled(editorStore.selectedFileURL == nil)
            }

            ToolbarItem {
                Button(action: { editorStore.refreshFiles() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh Folder")
            }
        }
    }

    private var sidebar: some View {
        List(selection: selectedFileBinding) {
            Section(editorStore.rootURL?.lastPathComponent ?? "Files") {
                OutlineGroup(editorStore.fileTree, children: \.children) { node in
                    sidebarRow(for: node)
                }
            }
        }
        .listStyle(.sidebar)
        .overlay(alignment: .bottomLeading) {
            if let errorMessage = editorStore.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(12)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: { showNewFileSheet = true }) {
                Label("New File", systemImage: "plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .buttonStyle(.plain)
            .background(.bar)
        }
        .sheet(isPresented: $showNewFileSheet) {
            newFileSheet
        }
    }

    private var editorView: some View {
        TextEditor(text: Bindable(editorStore).documentText)
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 24)
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No File Selected",
            systemImage: "doc.text",
            description: Text("Choose a text or markdown file from \(editorStore.rootURL?.path ?? "folder").")
        )
    }
    
    private var newFileSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New File")
                .font(.headline)

            TextField("File name", text: $newFileName)
                .textFieldStyle(.roundedBorder)

            Text("Plain Text (.txt)")
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") {
                    showNewFileSheet = false
                    newFileName = ""
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Create") {
                    editorStore.createFile(named: newFileName, extension: "txt")
                    showNewFileSheet = false
                    newFileName = ""
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(newFileName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 300)
    }

    private var selectedFileBinding: Binding<URL?> {
        Binding(
            get: { editorStore.selectedFileURL },
            set: { newValue in
                guard let newValue else { return }
                editorStore.selectFile(at: newValue)
            }
        )
    }

    @ViewBuilder
    private func sidebarRow(for node: EditorStore.FileNode) -> some View {
        if node.isDirectory {
            Label(node.name, systemImage: "folder")
        } else {
            Label(node.name, systemImage: "doc.text")
                .tag(Optional(node.url))
        }
    }
}

#Preview {
    ContentViewPreview()
}

private struct ContentViewPreview: View {
    @State private var editorStore = EditorStore()
    @State private var themeStore = ThemeStore()

    var body: some View {
        ContentView()
            .environment(editorStore)
            .environment(themeStore)
            .frame(width: 1100, height: 700)
    }
}
