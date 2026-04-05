//
//  WriterApp.swift
//  Writer
//

import SwiftUI

@main
struct WriterApp: App {
    @State private var editorStore = EditorStore()
    @State private var themeStore = ThemeStore()

    var body: some Scene {
        Window("Writer", id: "main") {
            ContentView()
                .environment(editorStore)
                .environment(themeStore)
        }
        .defaultSize(width: 1200, height: 760)
        .restorationBehavior(.disabled)
    }
}
