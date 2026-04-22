import XCTest
@testable import Writer

@MainActor
final class EditorStoreTests: XCTestCase {
    func testRefreshFilesFiltersFilesAndSelectsFirstEditableFile() throws {
        let rootURL = try makeTemporaryWorkspace()
        let draftsURL = rootURL.appendingPathComponent("Drafts", isDirectory: true)
        try FileManager.default.createDirectory(at: draftsURL, withIntermediateDirectories: true)
        try "draft".write(to: draftsURL.appendingPathComponent("chapter.md"), atomically: true, encoding: .utf8)
        try "alpha".write(to: rootURL.appendingPathComponent("alpha.txt"), atomically: true, encoding: .utf8)
        try "skip".write(to: rootURL.appendingPathComponent("image.png"), atomically: true, encoding: .utf8)
        try "hidden".write(to: rootURL.appendingPathComponent(".hidden.md"), atomically: true, encoding: .utf8)

        let store = EditorStore(rootURL: rootURL, restoreSavedFolder: false)

        XCTAssertEqual(store.fileTree.map(\.name), ["Drafts", "alpha.txt"])
        XCTAssertEqual(store.fileTree.first?.children?.map(\.name), ["chapter.md"])
        XCTAssertEqual(store.selectedFileURL?.lastPathComponent, "chapter.md")
        XCTAssertEqual(store.documentText, "draft")
    }

    func testPersistCurrentDocumentWritesChangesToDisk() throws {
        let rootURL = try makeTemporaryWorkspace()
        let fileURL = rootURL.appendingPathComponent("note.txt")
        try "before".write(to: fileURL, atomically: true, encoding: .utf8)

        let store = EditorStore(rootURL: rootURL, restoreSavedFolder: false)
        store.selectFile(at: fileURL)
        store.documentText = "after"

        store.persistCurrentDocument()

        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "after")
        XCTAssertNil(store.errorMessage)
    }

    func testCreateRenameMoveAndPasteItemsUpdateWorkspace() throws {
        let rootURL = try makeTemporaryWorkspace()
        let sourceURL = rootURL.appendingPathComponent("source.txt")
        try "content".write(to: sourceURL, atomically: true, encoding: .utf8)

        let store = EditorStore(rootURL: rootURL, restoreSavedFolder: false)

        store.createFolder(named: "Archive")
        let archiveURL = rootURL.appendingPathComponent("Archive", isDirectory: true)
        let inboxURL = rootURL.appendingPathComponent("Inbox", isDirectory: true)
        try FileManager.default.createDirectory(at: inboxURL, withIntermediateDirectories: true)

        store.renameItem(sourceURL, to: "renamed.txt")
        let renamedURL = rootURL.appendingPathComponent("renamed.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamedURL.path))

        XCTAssertTrue(store.moveItem(renamedURL, to: archiveURL))
        let movedURL = archiveURL.appendingPathComponent("renamed.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: movedURL.path))

        store.copyItems([movedURL])
        XCTAssertTrue(store.canPaste(into: rootURL))
        store.pasteItems(to: rootURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("renamed.txt").path))

        store.copyItems([archiveURL])
        XCTAssertFalse(store.canPaste(into: archiveURL))
        XCTAssertFalse(store.canPaste(into: archiveURL.appendingPathComponent("Nested", isDirectory: true)))

        store.cutItems([movedURL])
        store.pasteItems(to: inboxURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: inboxURL.appendingPathComponent("renamed.txt").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: movedURL.path))
        XCTAssertFalse(store.isClipboardCut)
        XCTAssertTrue(store.clipboardItems.isEmpty)
    }

    private func makeTemporaryWorkspace() throws -> URL {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: rootURL)
        }
        return rootURL
    }
}
