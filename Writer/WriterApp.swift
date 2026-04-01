//
//  WriterApp.swift
//  Writer
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var plainTextDocument: UTType {
        UTType.plainText
    }
}

struct TextDocument: FileDocument {
    var text: String

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [.plainText] }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

@main
struct WriterApp: App {
    @State private var themeStore = ThemeStore()

    var body: some Scene {
        DocumentGroup(newDocument: TextDocument()) { file in
            ContentView(document: file.$document)
                .environment(themeStore)
        }
    }
}
