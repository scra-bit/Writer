//
//  EditorStore.swift
//  Writer
//

import Foundation
import Observation
import AppKit

private enum BookmarkKeys {
    static let folderBookmark = "forthewriting_folder_bookmark"
}

@MainActor
@Observable
final class EditorStore {
    struct FileNode: Identifiable, Hashable {
        let url: URL
        let isDirectory: Bool
        let children: [FileNode]?

        var id: URL { url }
        var name: String { url.lastPathComponent }
    }

    private(set) var rootURL: URL?

    var fileTree: [FileNode] = []
    var selectedFileURL: URL?
    var documentText = ""
    var errorMessage: String?

    private var lastSavedText = ""
    private var autosaveTask: Task<Void, Never>?
    private var securityScopedAccessToken: Any?

    init() {
        initializeRootURL()
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
            documentText = text
            lastSavedText = text
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't open \(url.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func scheduleAutosave() {
        autosaveTask?.cancel()

        guard selectedFileURL != nil else { return }

        autosaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))

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
    
    func createFile(named name: String, extension ext: String) {
        guard let rootURL else {
            errorMessage = "No folder selected."
            return
        }

        var fileName = name.trimmingCharacters(in: .whitespaces)
        if fileName.isEmpty { fileName = "Untitled" }

        let fileURL = rootURL.appendingPathComponent("\(fileName).\(ext)")

        do {
            try "".write(to: fileURL, atomically: true, encoding: .utf8)
            refreshFiles()
            selectFile(at: fileURL)
        } catch {
            errorMessage = "Couldn't create file: \(error.localizedDescription)"
        }
    }

    private func loadNodes(in directoryURL: URL) throws -> [FileNode] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
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
}
