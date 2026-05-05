//
//  EditorStore.swift
//  Writer
//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors

import Foundation
import Observation
import AppKit

private enum BookmarkKeys {
    static let folderBookmark = "forthewriting_folder_bookmark"
    static let autosaveDelay = "forthewriting_autosave_delay"
    static let hideDotfiles = "forthewriting_hide_dotfiles"
}

@MainActor
@Observable
final class EditorStore {
    enum PendingCreation: String, Identifiable {
        case file
        case folder

        var id: String { rawValue }
    }

    struct FileNode: Identifiable, Hashable {
        let url: URL
        let isDirectory: Bool
        let children: [FileNode]?

        var id: URL { url }
        var name: String { url.lastPathComponent }
    }

    private(set) var rootURL: URL?

    var fileTree: [FileNode] = []
    private var expandedIDs: Set<URL> = []
    private var activeDirectoryURL: URL?

    func toggleExpansion(for url: URL) {
        activeDirectoryURL = url

        if expandedIDs.contains(url) {
            expandedIDs.remove(url)
        } else {
            expandedIDs.insert(url)
        }
    }

    func isExpanded(_ url: URL) -> Bool {
        expandedIDs.contains(url)
    }

    var selectedFileURL: URL?
    var documentText = ""
    var errorMessage: String?
    var pendingCreation: PendingCreation?

    var autosaveDelay: Double = {
        guard UserDefaults.standard.object(forKey: BookmarkKeys.autosaveDelay) != nil else {
            return 0.35  // Default: 350ms = 0.35 seconds
        }
        return UserDefaults.standard.double(forKey: BookmarkKeys.autosaveDelay)
    }() {
        didSet {
            UserDefaults.standard.set(autosaveDelay, forKey: BookmarkKeys.autosaveDelay)
        }
    }
    var hideDotfiles: Bool = {
        UserDefaults.standard.object(forKey: BookmarkKeys.hideDotfiles) as? Bool ?? true
    }() {
        didSet {
            UserDefaults.standard.set(hideDotfiles, forKey: BookmarkKeys.hideDotfiles)
        }
    }

    private var lastSavedText = ""
    private var autosaveTask: Task<Void, Never>?
    private var securityScopedAccessToken: Any?

    // Clipboard for file operations
    var clipboardItems: [URL] = []
    var isClipboardCut = false

    init(rootURL: URL? = nil, restoreSavedFolder: Bool = true) {
        if let rootURL {
            self.rootURL = rootURL
            refreshFiles()
        } else if restoreSavedFolder {
            initializeRootURL()
        } else {
            self.rootURL = nil
            fileTree = []
            selectedFileURL = nil
            documentText = ""
            lastSavedText = ""
        }
    }

    // MARK: - File Operations

    func copyItems(_ urls: [URL]) {
        setClipboard(urls, isCut: false)
    }

    func cutItems(_ urls: [URL]) {
        setClipboard(urls, isCut: true)
    }
    
    private func setClipboard(_ urls: [URL], isCut: Bool) {
        clipboardItems = urls
        isClipboardCut = isCut
    }

    func pasteItems(to destinationDirectory: URL) {
        guard !clipboardItems.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        var newURLs: [URL] = []

        for url in clipboardItems {
            let destinationURL = destinationDirectory.appendingPathComponent(url.lastPathComponent)

            do {
                if isClipboardCut {
                    try FileManager.default.moveItem(at: url, to: destinationURL)
                } else {
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                }
                newURLs.append(destinationURL)
            } catch {
                errorMessage = "Failed to \(isClipboardCut ? "move" : "copy") \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }

        if isClipboardCut {
            clipboardItems = []
            isClipboardCut = false
        }

        refreshFiles()

        // If we pasted a single file, select it
        if newURLs.count == 1, let newFile = newURLs.first, !newFile.hasDirectoryPath {
            selectFile(at: newFile)
        }
    }

    func canPaste(into directory: URL) -> Bool {
        guard !clipboardItems.isEmpty else { return false }
        // Don't allow pasting into a location that would create a cycle or paste onto itself
        return !clipboardItems.contains { item in
            item == directory || directory.path.hasPrefix(item.path + "/")
        }
    }

    func moveItem(_ sourceURL: URL, to destinationDirectory: URL) -> Bool {
        let destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)

        guard sourceURL != destinationURL else { return false }

        do {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            refreshFiles()
            return true
        } catch {
            errorMessage = "Failed to move \(sourceURL.lastPathComponent): \(error.localizedDescription)"
            return false
        }
    }

    func deleteItem(_ url: URL) {
        let alert = NSAlert()
        alert.messageText = "Delete \"\(url.lastPathComponent)\"?"
        alert.informativeText = "This item will be moved to the trash."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Move to Trash")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                if selectedFileURL == url {
                    selectedFileURL = nil
                    documentText = ""
                    lastSavedText = ""
                }
                refreshFiles()
            } catch {
                errorMessage = "Failed to delete \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }
    }

    func renameItem(_ url: URL, to newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, trimmedName != url.lastPathComponent else { return }

        let newURL = url.deletingLastPathComponent().appendingPathComponent(trimmedName)

        do {
            try FileManager.default.moveItem(at: url, to: newURL)
            if selectedFileURL == url {
                selectedFileURL = newURL
            }
            refreshFiles()
        } catch {
            errorMessage = "Failed to rename \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func revealInFinder(_ url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func openFolder(_ url: URL) {
        NSWorkspace.shared.open(url)
    }

    private func initializeRootURL() {
        if let savedURL = loadSavedFolder() {
            rootURL = savedURL
            refreshFiles()
        } else {
            promptForFolderSelection()
        }
    }

    func promptForFolderSelection() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select your writing folder"
        panel.prompt = "Select Folder"

        guard panel.runModal() == .OK, let url = panel.url else {
            errorMessage = "No folder selected. Please select a folder to continue."
            return
        }

        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            UserDefaults.standard.set(bookmarkData, forKey: BookmarkKeys.folderBookmark)

            rootURL = url
            securityScopedAccessToken = url.startAccessingSecurityScopedResource()
            refreshFiles()
        } catch {
            errorMessage = "Failed to create folder bookmark: \(error.localizedDescription)"
        }
    }

    private func loadSavedFolder() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: BookmarkKeys.folderBookmark) else {
            return nil
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                let updatedBookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                UserDefaults.standard.set(updatedBookmarkData, forKey: BookmarkKeys.folderBookmark)
            }

            securityScopedAccessToken = url.startAccessingSecurityScopedResource()
            return url
        } catch {
            UserDefaults.standard.removeObject(forKey: BookmarkKeys.folderBookmark)
            return nil
        }
    }

    var currentTitle: String {
        selectedFileURL?.lastPathComponent ?? "Writer"
    }

    var currentDocumentURL: URL? {
        guard let selectedFileURL, !selectedFileURL.hasDirectoryPath else {
            return nil
        }
        return selectedFileURL
    }

    var newFileDirectoryURL: URL? {
        if let activeDirectoryURL, containsDirectory(at: activeDirectoryURL, in: fileTree) {
            return activeDirectoryURL
        }

        if let selectedFileURL {
            return selectedFileURL.deletingLastPathComponent()
        }

        return rootURL
    }

    func refreshFiles() {
        guard let rootURL else {
            fileTree = []
            selectedFileURL = nil
            documentText = ""
            lastSavedText = ""
            errorMessage = "No folder selected. Please select a folder to continue."
            return
        }

        do {
            guard FileManager.default.fileExists(atPath: rootURL.path) else {
                fileTree = []
                selectedFileURL = nil
                documentText = ""
                lastSavedText = ""
                errorMessage = "Folder not found: \(rootURL.path)"
                return
            }

            let previousSelection = selectedFileURL
            fileTree = try loadNodes(in: rootURL)
            errorMessage = nil

            if let previousSelection, containsFile(at: previousSelection, in: fileTree) {
                selectFile(at: previousSelection)
            } else if let firstFileURL = firstFileURL(in: fileTree) {
                selectFile(at: firstFileURL)
            } else {
                selectedFileURL = nil
                documentText = ""
                lastSavedText = ""
            }

            if let activeDirectoryURL, !containsDirectory(at: activeDirectoryURL, in: fileTree) {
                self.activeDirectoryURL = nil
            }
        } catch {
            fileTree = []
            selectedFileURL = nil
            documentText = ""
            lastSavedText = ""
            errorMessage = error.localizedDescription
        }
    }

    func selectFile(at url: URL) {
        guard selectedFileURL != url else { return }

        persistCurrentDocument()

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            selectedFileURL = url
            activeDirectoryURL = url.deletingLastPathComponent()
            documentText = text
            lastSavedText = text
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't open \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func selectItem(at url: URL, isDirectory: Bool) {
        if isDirectory {
            // For folders: just track as active directory, don't try to open
            activeDirectoryURL = url
            // Still update selection for UI highlighting
            selectedFileURL = url
        } else {
            selectFile(at: url)
        }
    }

    func scheduleAutosave() {
        autosaveTask?.cancel()

        guard selectedFileURL != nil else { return }

        autosaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(Int(autosaveDelay * 1000)))

            guard !Task.isCancelled else { return }
            persistCurrentDocument()
        }
    }

    func persistCurrentDocument() {
        autosaveTask?.cancel()

        guard let selectedFileURL, documentText != lastSavedText else { return }

        do {
            try documentText.write(to: selectedFileURL, atomically: true, encoding: .utf8)
            lastSavedText = documentText
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't save \(selectedFileURL.lastPathComponent): \(error.localizedDescription)"
        }
    }
    
    func formatAllTables() {
        let formatter = TableFormatter()
        documentText = formatter.formatEntireDocument(documentText)
    }
    
    func createFile(named name: String, extension ext: String) {
        guard let targetDirectoryURL = newFileDirectoryURL else {
            errorMessage = "No folder selected."
            return
        }

        var fileName = name.trimmingCharacters(in: .whitespaces)
        if fileName.isEmpty { fileName = "Untitled" }

        let fileURL = targetDirectoryURL.appendingPathComponent("\(fileName).\(ext)")

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            refreshFiles()
            selectFile(at: fileURL)
        } catch {
            errorMessage = "Couldn't create file: \(error.localizedDescription)"
        }
    }

    func createFolder(named name: String) {
        guard let targetDirectoryURL = newFileDirectoryURL else {
            errorMessage = "No folder selected."
            return
        }

        var folderName = name.trimmingCharacters(in: .whitespaces)
        if folderName.isEmpty { folderName = "Untitled Folder" }

        let folderURL = targetDirectoryURL.appendingPathComponent(folderName, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
            activeDirectoryURL = folderURL
            refreshFiles()
            expandedIDs.insert(folderURL)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't create folder: \(error.localizedDescription)"
        }
    }

    private func loadNodes(in directoryURL: URL) throws -> [FileNode] {
        let options: FileManager.DirectoryEnumerationOptions = hideDotfiles ? [.skipsHiddenFiles] : []
        let contents = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: options
        )

        return try contents
            .sorted(by: sortURLs(_:_:))
            .compactMap { url in
                let values = try url.resourceValues(forKeys: [.isDirectoryKey])
                let isDirectory = values.isDirectory ?? false

                if isDirectory {
                    return FileNode(
                        url: url,
                        isDirectory: true,
                        children: try loadNodes(in: url)
                    )
                }

                guard isEditableFile(url) else {
                    return nil
                }

                return FileNode(url: url, isDirectory: false, children: nil)
            }
    }

    private func sortURLs(_ lhs: URL, _ rhs: URL) -> Bool {
        let lhsIsDirectory = (try? lhs.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
        let rhsIsDirectory = (try? rhs.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false

        if lhsIsDirectory != rhsIsDirectory {
            return lhsIsDirectory && !rhsIsDirectory
        }

        return lhs.lastPathComponent.localizedCaseInsensitiveCompare(rhs.lastPathComponent) == .orderedAscending
    }

    private func isEditableFile(_ url: URL) -> Bool {
        let allowedExtensions = ["md", "markdown", "txt", "text"]

        guard !url.pathExtension.isEmpty else {
            return true
        }

        return allowedExtensions.contains(url.pathExtension.lowercased())
    }

    private func firstFileURL(in nodes: [FileNode]) -> URL? {
        for node in nodes {
            if node.isDirectory {
                if let childURL = firstFileURL(in: node.children ?? []) {
                    return childURL
                }
            } else {
                return node.url
            }
        }

        return nil
    }

    private func containsFile(at url: URL, in nodes: [FileNode]) -> Bool {
        nodes.contains { node in
            if node.url == url {
                return !node.isDirectory
            }

            return containsFile(at: url, in: node.children ?? [])
        }
    }

    private func containsDirectory(at url: URL, in nodes: [FileNode]) -> Bool {
        nodes.contains { node in
            if node.url == url {
                return node.isDirectory
            }

            return containsDirectory(at: url, in: node.children ?? [])
        }
    }
}
