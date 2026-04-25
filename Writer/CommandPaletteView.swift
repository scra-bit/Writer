//
//  CommandPaletteView.swift
//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//

import SwiftUI

struct CommandPaletteView: View {
    @Environment(CommandPaletteStore.self) private var store
    @FocusState private var isSearchFocused: Bool

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { store.searchText },
            set: { store.searchText = $0 }
        )
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Search field
                searchField

                Divider()

                // Commands list
                commandsList
            }
            .frame(width: 520)
            .background(Color(nsColor: .windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 8)
            .onAppear {
                isSearchFocused = true
            }

            // Invisible keyboard shortcut handlers
            keyboardShortcuts
        }
        .scaleEffect(store.isVisible ? 1 : 0.95)
        .opacity(store.isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.2), value: store.isVisible)
        .allowsHitTesting(store.isVisible)
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Type a command...", text: searchTextBinding)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium))
                .focused($isSearchFocused)

            if !store.searchText.isEmpty {
                Button {
                    store.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Commands List

    private var commandsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(store.filteredCommands.enumerated()), id: \.element.id) { index, command in
                        Button {
                            store.execute(id: command.id)
                        } label: {
                            CommandRowView(
                                command: command,
                                isSelected: index == store.selectedIndex
                            )
                        }
                        .buttonStyle(.plain)
                        .id(index)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .onChange(of: store.selectedIndex) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    // MARK: - Keyboard Shortcuts

    private var keyboardShortcuts: some View {
        ZStack {
            Button("") {
                store.moveSelection(by: -1)
            }
            .keyboardShortcut(.upArrow, modifiers: [])

            Button("") {
                store.moveSelection(by: 1)
            }
            .keyboardShortcut(.downArrow, modifiers: [])

            Button("") {
                store.executeSelected()
            }
            .keyboardShortcut(.return, modifiers: [])

            Button("") {
                store.hide()
            }
            .keyboardShortcut(.escape, modifiers: [])
        }
        .opacity(0)
    }
}

// MARK: - Command Row View

struct CommandRowView: View {
    let command: Command
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(command.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            if !command.keyEquivalent.isEmpty {
                shortcutPill(command)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func shortcutPill(_ command: Command) -> some View {
        HStack(spacing: 4) {
            if command.modifiers.contains(.command) {
                Text("⌘")
            }
            if command.modifiers.contains(.shift) {
                Text("⇧")
            }
            Text(command.keyEquivalent.uppercased())
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.primary.opacity(0.06))
        )
    }
}