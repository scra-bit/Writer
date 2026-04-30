//
//  ContentView.swift
//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//

import SwiftUI

// HTMLExporter is defined in HTMLExporter.swift within the same module

struct ContentView: View {
    @State private var creationName = ""
    @Environment(EditorStore.self) private var editorStore
    @Environment(ThemeStore.self) private var themeStore
    @Environment(LayoutStore.self) private var layoutStore
    @Environment(CommandPaletteStore.self) private var commandPaletteStore
    @State private var renamingURL: URL?
    @State private var renamingText = ""
    @State private var dropTargetURL: URL?

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            Group {
                if editorStore.selectedFileURL == nil {
                    Text("No file found. Sorry.")
                } else {
                    layoutContainer
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(editorStore.currentTitle)
        .onChange(of: editorStore.documentText) { _, _ in
            editorStore.scheduleAutosave()
        }
        .onChange(of: renamingURL) { _, newValue in
            if newValue == nil {
                renamingText = ""
            }
        }
        .sheet(item: Bindable(editorStore).pendingCreation) { creation in
            creationSheet(for: creation)
        }
        .toolbar {
            ToolbarItem {
                Button(action: { layoutStore.showPreview.toggle() }) {
                    Image(
                        systemName: layoutStore.showPreview
                            ? "arrowtriangle.forward.square.fill" : "arrowtriangle.forward.square")
                }
                .help(layoutStore.showPreview ? "Hide Preview" : "Show Preview")
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
        .overlay {
            if commandPaletteStore.isVisible {
                CommandPaletteView()
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
        .dropDestination(
            for: URL.self,
            action: { urls, _ in
                handleDrop(urls: urls, onto: editorStore.rootURL ?? URL(fileURLWithPath: ""))
                return true
            },
            isTargeted: { isTargeted in
                if isTargeted {
                    dropTargetURL = editorStore.rootURL
                } else if dropTargetURL == editorStore.rootURL {
                    dropTargetURL = nil
                }
            }
        )
        .contextMenu {
            if let rootURL = editorStore.rootURL {
                Button("New File") {
                    editorStore.pendingCreation = .file
                }

                Button("New Folder") {
                    editorStore.pendingCreation = .folder
                }

                if editorStore.canPaste(into: rootURL) {
                    Divider()

                    Button("Paste") {
                        editorStore.pasteItems(to: rootURL)
                    }
                }

                Divider()

                Button("Show in Finder") {
                    editorStore.revealInFinder(rootURL)
                }

                Button("Open in Finder") {
                    editorStore.openFolder(rootURL)
                }
            }
        }
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
        GeometryReader { geometry in
            HStack {
                Spacer()

                MarkdownTextView(
                    text: Bindable(editorStore).documentText,
                    documentURL: editorStore.currentDocumentURL,
                    workspaceRootURL: editorStore.rootURL
                )
                    .frame(
                        width: min(800, geometry.size.width * 0.85),
                        height: geometry.size.height,
                        alignment: .center
                    )

                Spacer()
            }
        }
    }

    private var layoutContainer: some View {
        HSplitView {
            editorView
                .frame(minWidth: 280)
            previewContainer
                .frame(minWidth: layoutStore.showPreview ? 280 : 0)
                .frame(maxWidth: layoutStore.showPreview ? .infinity : 0)
        }
    }

    private var previewContainer: some View {
        WebView(
            markdown: editorStore.documentText,
            theme: themeStore.previewTheme,
            renderContext: MarkdownRenderContext(
                documentURL: editorStore.currentDocumentURL,
                workspaceRootURL: editorStore.rootURL
            )
        )
        .opacity(layoutStore.showPreview ? 1 : 0)
        .disabled(!layoutStore.showPreview)
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No File Selected",
            systemImage: "doc.text",
            description: Text(
                "Choose a text or markdown file from \(editorStore.rootURL?.path ?? "folder").")
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

    private func sidebarNodeRow(for node: EditorStore.FileNode, depth: Int = 0) -> AnyView {
        let isRenaming = renamingURL == node.url
        let isDropTarget = dropTargetURL == node.url && node.isDirectory

        if node.isDirectory {
            let view = DisclosureGroup(
                isExpanded: Binding(
                    get: { editorStore.isExpanded(node.url) },
                    set: { _ in editorStore.toggleExpansion(for: node.url) }
                )
            ) {
                if let children = node.children {
                    ForEach(children) { childNode in
                        sidebarNodeRow(for: childNode, depth: depth + 1)
                    }
                }
            } label: {
                folderLabel(for: node, isRenaming: isRenaming, isDropTarget: isDropTarget)
            }
            .tag(Optional(node.url))
            .contextMenu {
                folderContextMenu(for: node)
            }
            .dropDestination(
                for: URL.self,
                action: { urls, _ in
                    handleDrop(urls: urls, onto: node.url)
                    return true
                },
                isTargeted: { isTargeted in
                    if isTargeted {
                        dropTargetURL = node.url
                    } else if dropTargetURL == node.url {
                        dropTargetURL = nil
                    }
                }
            )
            return AnyView(view)
        }

        let view = Group {
            if isRenaming {
                renamingField(for: node)
                    .tag(Optional(node.url))
            } else {
                fileLabel(for: node)
                    .tag(Optional(node.url))
                    .contextMenu {
                        fileContextMenu(for: node)
                    }
            }
        }
        return AnyView(view)
    }

    // MARK: - Labels and Views

    @ViewBuilder
    private func folderLabel(for node: EditorStore.FileNode, isRenaming: Bool, isDropTarget: Bool)
        -> some View
    {
        if isRenaming {
            renamingField(for: node)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 10))
                    .onDrag {
                        NSItemProvider(object: node.url as NSURL)
                    }

                Label(node.name, systemImage: isDropTarget ? "folder.fill" : "folder")
                    .contentShape(Rectangle())
            }
            .contentShape(Rectangle())
            .onTapGesture {
                editorStore.selectItem(at: node.url, isDirectory: true)
            }
        }
    }

    @ViewBuilder
    private func fileLabel(for node: EditorStore.FileNode) -> some View {
        let ext = node.url.pathExtension.lowercased()
        let iconName: String = {
            switch ext {
            case "md", "markdown": return "doc.text"
            case "txt", "text": return "doc.plaintext"
            default: return "doc"
            }
        }()

        HStack(spacing: 4) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
                .font(.system(size: 10))
                .onDrag {
                    NSItemProvider(object: node.url as NSURL)
                }

            Label(node.name, systemImage: iconName)
                .contentShape(Rectangle())
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editorStore.selectItem(at: node.url, isDirectory: false)
        }
    }

    @ViewBuilder
    private func renamingField(for node: EditorStore.FileNode) -> some View {
        TextField("Name", text: $renamingText)
            .textFieldStyle(.roundedBorder)
            .onSubmit {
                finishRenaming()
            }
            .onAppear {
                renamingText = node.name
            }
    }

    // MARK: - Context Menus

    @ViewBuilder
    private func fileContextMenu(for node: EditorStore.FileNode) -> some View {
        Button("Open") {
            editorStore.selectFile(at: node.url)
        }

        Divider()

        Button("Rename") {
            startRenaming(node.url)
        }

        Button("Duplicate") {
            duplicateItem(at: node.url)
        }

        Divider()

        Button("Copy") {
            editorStore.copyItems([node.url])
        }

        Button("Cut") {
            editorStore.cutItems([node.url])
        }

        if editorStore.canPaste(into: node.url.deletingLastPathComponent()) {
            Button("Paste") {
                editorStore.pasteItems(to: node.url.deletingLastPathComponent())
            }
        }

        Divider()

        Button("Show in Finder") {
            editorStore.revealInFinder(node.url)
        }

        Button("Move to Trash", role: .destructive) {
            editorStore.deleteItem(node.url)
        }
    }

    @ViewBuilder
    private func folderContextMenu(for node: EditorStore.FileNode) -> some View {
        Button("New File") {
            editorStore.pendingCreation = .file
        }

        Button("New Folder") {
            editorStore.pendingCreation = .folder
        }

        Divider()

        Button("Rename") {
            startRenaming(node.url)
        }

        Divider()

        Button("Copy") {
            editorStore.copyItems([node.url])
        }

        Button("Cut") {
            editorStore.cutItems([node.url])
        }

        if editorStore.canPaste(into: node.url) {
            Button("Paste") {
                editorStore.pasteItems(to: node.url)
            }
        }

        Divider()

        Button("Show in Finder") {
            editorStore.revealInFinder(node.url)
        }

        Button("Open in Finder") {
            editorStore.openFolder(node.url)
        }

        Button("Move to Trash", role: .destructive) {
            editorStore.deleteItem(node.url)
        }
    }

    // MARK: - Actions

    private func startRenaming(_ url: URL) {
        renamingURL = url
        renamingText = url.lastPathComponent
    }

    private func finishRenaming() {
        guard let url = renamingURL else { return }
        editorStore.renameItem(url, to: renamingText)
        renamingURL = nil
        renamingText = ""
    }

    private func duplicateItem(at url: URL) {
        let parent = url.deletingLastPathComponent()
        let baseName = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        var newName = baseName + " copy"
        if !ext.isEmpty {
            newName += "." + ext
        }

        var counter = 2
        var destinationURL = parent.appendingPathComponent(newName)

        while FileManager.default.fileExists(atPath: destinationURL.path) {
            newName = baseName + " copy \(counter)"
            if !ext.isEmpty {
                newName += "." + ext
            }
            destinationURL = parent.appendingPathComponent(newName)
            counter += 1
        }

        do {
            try FileManager.default.copyItem(at: url, to: destinationURL)
            editorStore.refreshFiles()
            if !destinationURL.hasDirectoryPath {
                editorStore.selectFile(at: destinationURL)
            }
        } catch {
            editorStore.errorMessage = "Failed to duplicate: \(error.localizedDescription)"
        }
    }

    private func handleDrop(urls: [URL], onto destinationURL: URL) {
        dropTargetURL = nil

        let destinationDirectory =
            destinationURL.hasDirectoryPath
            ? destinationURL : destinationURL.deletingLastPathComponent()

        for sourceURL in urls {
            // Don't move onto itself
            guard
                sourceURL != destinationDirectory
                    && sourceURL.deletingLastPathComponent() != destinationDirectory
            else { continue }

            let newURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)

            // Handle duplicate names
            if FileManager.default.fileExists(atPath: newURL.path) {
                let alert = NSAlert()
                alert.messageText = "\"\(newURL.lastPathComponent)\" already exists"
                alert.informativeText = "Do you want to replace it?"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Replace")
                alert.addButton(withTitle: "Skip")

                if alert.runModal() == .alertFirstButtonReturn {
                    // Remove existing and move
                    try? FileManager.default.removeItem(at: newURL)
                    _ = editorStore.moveItem(sourceURL, to: destinationDirectory)
                }
            } else {
                _ = editorStore.moveItem(sourceURL, to: destinationDirectory)
            }
        }
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
