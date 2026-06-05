//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//  ThemeEditorView.swift
//  Writer
//

import SwiftUI

struct ThemeEditorView: View {
    @Environment(ThemeStore.self) private var themeStore

    var body: some View {
        Form {
            // Color Scheme Picker
            Picker("Color Scheme", selection: Bindable(themeStore).previewColorScheme) {
                ForEach(ThemeStore.PreviewColorScheme.allCases, id: \.self) { scheme in
                    Text(scheme.title).tag(scheme)
                }
            }
            .pickerStyle(.segmented)

            // Typography Theme Picker
            Picker(
                "Typography",
                selection: Binding(
                    get: { themeStore.previewTheme.name },
                    set: { _ in }  // Selection doesn't change - both use sans-serif
                )
            ) {
                Text("Sans Serif").tag("Sans Serif")
            }
            .disabled(true)
            .help("Additional typography options coming soon")

            HStack {
                Text("Base Font Size")
                Spacer()
                TextField(
                    "Size",
                    value: Bindable(themeStore).baseFontSize,
                    format: .number.precision(.fractionLength(0))
                )
                .multilineTextAlignment(.trailing)
                .frame(width: 64)
                Text("pt")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(minWidth: 320, idealWidth: 360, minHeight: 180)
    }
}
