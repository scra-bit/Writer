//
//  ThemeEditorView.swift
//  Writer
//

//

import SwiftUI

struct ThemeEditorView: View {
    @Environment(ThemeStore.self) private var themeStore

    var body: some View {
        Form {
            // Typography Theme Picker
            Picker("Typography", selection: Bindable(themeStore).previewTheme) {
                ForEach(PreviewTheme.allThemes, id: \.name) { theme in
                    Text(theme.name).tag(theme)
                }
            }

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
