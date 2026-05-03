//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//  PreferencesView.swift
//  Writer
//

import SwiftUI

struct PreferencesView: View {
    @Environment(EditorStore.self) private var editorStore
    @Environment(ThemeStore.self) private var themeStore
    @Environment(LayoutStore.self) private var layoutStore

    var body: some View {
        TabView {
            EditorPreferencesView()
                .tabItem { Label("Editor", systemImage: "pencil") }

            PreviewPreferencesView()
                .tabItem { Label("Preview", systemImage: "eye") }

            ExportPreferencesView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }

            WorkspacePreferencesView()
                .tabItem { Label("Workspace", systemImage: "folder") }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Editor Preferences

struct EditorPreferencesView: View {
    @Environment(EditorStore.self) private var editorStore

    var body: some View {
        Form {
            Section("Autosave") {
                HStack {
                    Text("Delay")
                    Spacer()
                    Slider(
                        value: Bindable(editorStore).autosaveDelay,
                        in: 0.5...10.0,
                        step: 0.5
                    ) {
                        Text("Autosave Delay")
                    } minimumValueLabel: {
                        Text("0.5s")
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("10s")
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.1fs", editorStore.autosaveDelay))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .trailing)
                }
            }

            Section("Editing") {
                Toggle("Smart Dashes", isOn: .constant(false))
                Toggle("Smart Quotes", isOn: .constant(false))
            }
        }
        .padding(20)
        .frame(minWidth: 320, idealWidth: 400)
    }
}

// MARK: - Preview Preferences

struct PreviewPreferencesView: View {
    var body: some View {
        ThemeEditorView()
    }
}

// MARK: - Export Preferences

struct ExportPreferencesView: View {
    var body: some View {
        Form {
            Section("HTML Export") {
                Toggle("Include CSS", isOn: .constant(true))
                Toggle("Inline Styles", isOn: .constant(false))
            }

            Section("PDF Export") {
                Toggle("Include Page Numbers", isOn: .constant(true))
            }
        }
        .padding(20)
        .frame(minWidth: 320, idealWidth: 400)
    }
}

// MARK: - Workspace Preferences

struct WorkspacePreferencesView: View {
    @Environment(EditorStore.self) private var editorStore

    var body: some View {
        Form {
            Section("File Browser") {
                Toggle("Hide Dotfiles", isOn: Bindable(editorStore).hideDotfiles)
                Toggle("Show File Extensions", isOn: .constant(true))
            }

            Section("Behavior") {
                Toggle("Restore Folder on Launch", isOn: .constant(true))
            }
        }
        .padding(20)
        .frame(minWidth: 320, idealWidth: 400)
    }
}
