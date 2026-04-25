////   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//  CommandPaletteStore.swift
//  Writer
//

import SwiftUI
import Observation

struct Command: Identifiable {
    let id: String
    let title: String
    let keyEquivalent: String
    let modifiers: EventModifiers
    var action: () -> Void
}

@MainActor
@Observable
final class CommandPaletteStore {
    var isVisible = false
    var searchText = ""
    var selectedIndex = 0

    var commands: [Command] = [
        Command(id: "exportHTML", title: "Export to HTML", keyEquivalent: "e", modifiers: .command.union(.shift), action: {}),
        Command(id: "exportPDF", title: "Export to PDF", keyEquivalent: "d", modifiers: .command.union(.shift), action: {}),
        Command(id: "exportRTF", title: "Export to RTF", keyEquivalent: "r", modifiers: .command.union(.shift), action: {}),
        Command(id: "formatTables", title: "Format Tables", keyEquivalent: "f", modifiers: .command.union(.shift), action: {}),
        Command(id: "newFile", title: "New File", keyEquivalent: "n", modifiers: .command, action: {}),
        Command(id: "newFolder", title: "New Folder", keyEquivalent: "n", modifiers: .command.union(.shift), action: {}),
        Command(id: "refreshFolder", title: "Refresh Folder", keyEquivalent: "", modifiers: [], action: {}),
        Command(id: "save", title: "Save", keyEquivalent: "s", modifiers: .command, action: {}),
        Command(id: "togglePreview", title: "Show/Hide Preview", keyEquivalent: "/", modifiers: .command, action: {}),
    ]

    var filteredCommands: [Command] {
        if searchText.isEmpty {
            return commands.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
        return commands
            .filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func show() {
        isVisible = true
        searchText = ""
        selectedIndex = 0
    }

    func hide() {
        isVisible = false
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func moveSelection(by delta: Int) {
        let count = filteredCommands.count
        guard count > 0 else { return }
        selectedIndex = (selectedIndex + delta + count) % count
    }

    func executeSelected() {
        guard selectedIndex >= 0 && selectedIndex < filteredCommands.count else { return }
        filteredCommands[selectedIndex].action()
        hide()
    }

    func execute(id: String) {
        guard let command = commands.first(where: { $0.id == id }) else { return }
        command.action()
        hide()
    }

    func setAction(for id: String, action: @escaping () -> Void) {
        guard let index = commands.firstIndex(where: { $0.id == id }) else { return }
        commands[index].action = action
    }
}