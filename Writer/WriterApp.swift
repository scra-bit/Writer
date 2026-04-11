//
//  WriterApp.swift
//  Writer
//

import SwiftUI

@main
struct WriterApp: App {
    @State private var editorStore = EditorStore()
    @State private var themeStore = ThemeStore()
    @State private var layoutStore = LayoutStore()
    @State private var exportError: String? = nil
    @State private var exportSuccess: String? = nil

    private func exportToHTML() {
        let exporter = HTMLExporter(
            markdown: editorStore.documentText, theme: themeStore.previewTheme)
        let suggestedName =
            (editorStore.selectedFileURL?.deletingPathExtension().lastPathComponent ?? "document")
            + ".html"
        Task {
            do {
                let url = try await exporter.save(suggestedName: suggestedName)
                exportSuccess = url.path
            } catch let error as any Error where (error as NSError).code != NSUserCancelledError {
                exportError = error.localizedDescription
            }
        }
    }

    private func exportToPDF() {
        let exporter = PDFExporter(
            markdown: editorStore.documentText, theme: themeStore.previewTheme)
        let suggestedName =
            (editorStore.selectedFileURL?.deletingPathExtension().lastPathComponent ?? "document")
            + ".pdf"
        Task {
            do {
                let url = try await exporter.save(suggestedName: suggestedName)
                exportSuccess = url.path
            } catch let error as any Error where (error as NSError).code != NSUserCancelledError {
                exportError = error.localizedDescription
            }
        }
    }

    private func exportToRTF() {
        let exporter = RTFExporter(
            markdown: editorStore.documentText, theme: themeStore.previewTheme)
        let suggestedName =
            (editorStore.selectedFileURL?.deletingPathExtension().lastPathComponent ?? "document")
            + ".rtf"
        Task {
            do {
                let url = try await exporter.save(suggestedName: suggestedName)
                exportSuccess = url.path
            } catch let error as any Error where (error as NSError).code != NSUserCancelledError {
                exportError = error.localizedDescription
            }
        }
    }

    var body: some Scene {
        Window("Writer", id: "main") {
            ContentView()
                .environment(editorStore)
                .environment(themeStore)
                .environment(layoutStore)
                .alert(
                    "Export Error",
                    isPresented: Binding(
                        get: { exportError != nil },
                        set: { if !$0 { exportError = nil } }
                    )
                ) {
                    Button("OK") {
                        exportError = nil
                    }
                } message: {
                    Text(exportError ?? "")
                }
                .onChange(of: exportSuccess) { _, newValue in
                    if newValue != nil {
                        Task {
                            try? await Task.sleep(for: .seconds(3))
                            exportSuccess = nil
                        }
                    }
                }
        }
        .defaultSize(width: 1200, height: 760)
        .restorationBehavior(.disabled)
        .commands {
            CommandMenu("File") {
                Button("New File") {
                    editorStore.pendingCreation = .file
                }
                .keyboardShortcut("n", modifiers: [.command])
                .disabled(editorStore.newFileDirectoryURL == nil)

                Button("New Folder") {
                    editorStore.pendingCreation = .folder
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                .disabled(editorStore.newFileDirectoryURL == nil)

                Divider()

                Button("Export to HTML") {
                    exportToHTML()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(editorStore.selectedFileURL == nil && editorStore.documentText.isEmpty)

                Button("Export to PDF") {
                    exportToPDF()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(editorStore.selectedFileURL == nil && editorStore.documentText.isEmpty)

                Button("Export to RTF") {
                    exportToRTF()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(editorStore.selectedFileURL == nil && editorStore.documentText.isEmpty)

                Divider()

                Button("Format Tables") {
                    editorStore.formatAllTables()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .disabled(editorStore.selectedFileURL == nil && editorStore.documentText.isEmpty)
            }
            CommandMenu("View") {
                Button("Show/Hide Preview") {
                    layoutStore.showPreview.toggle()
                }
                .keyboardShortcut("p", modifiers: [.command, .option])
            }
        }
    }
}
