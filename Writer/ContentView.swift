//
//  ContentView.swift
//  Writer
//

import SwiftUI

// HTMLExporter is defined in HTMLExporter.swift within the same module

struct ContentView: View {
    @State private var creationName = ""
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
        .sheet(item: Bindable(editorStore).pendingCreation) { creation in
            creationSheet(for: creation)
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
                ForEach(editorStore.fileTree) { node in
                    sidebarNodeRow(for: node)
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
    }

    private var editorView: some View {
        TextEditor(text: Bindable(editorStore).documentText)
            .font(.system(size: 16, design: .monospaced))
            .lineSpacing(3)
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
    
    @ViewBuilder
    private func creationSheet(for creation: EditorStore.PendingCreation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(creation == .file ? "New File" : "New Folder")
                .font(.headline)

            TextField(creation == .file ? "File name" : "Folder name", text: $creationName)
                .textFieldStyle(.roundedBorder)

            if creation == .file {
                Text("Plain Text (.txt)")
                    .foregroundStyle(.secondary)
            }

            if let targetDirectory = editorStore.newFileDirectoryURL {
                Text("Create in \(targetDirectory.path)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            HStack {
                Button("Cancel") {
                    editorStore.pendingCreation = nil
                    creationName = ""
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Create") {
                    if creation == .file {
                        editorStore.createFile(named: creationName, extension: "txt")
                    } else {
                        editorStore.createFolder(named: creationName)
                    }
                    editorStore.pendingCreation = nil
                    creationName = ""
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .disabled(creationName.trimmingCharacters(in: .whitespaces).isEmpty)
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

    private func sidebarNodeRow(for node: EditorStore.FileNode) -> AnyView {
        if node.isDirectory {
            return AnyView(
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { editorStore.isExpanded(node.url) },
                        set: { _ in editorStore.toggleExpansion(for: node.url) }
                    )
                ) {
                    if let children = node.children {
                        ForEach(children) { childNode in
                            sidebarNodeRow(for: childNode)
                        }
                    }
                } label: {
                    Label(node.name, systemImage: "folder")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            editorStore.toggleExpansion(for: node.url)
                        }
                }
            )
        }

        return AnyView(
            Label(node.name, systemImage: "doc.text")
                .tag(Optional(node.url))
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
