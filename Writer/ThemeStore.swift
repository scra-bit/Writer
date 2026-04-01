//
//  ThemeStore.swift
//  Writer
//
//
//

import Observation
import SwiftUI

@Observable
final class ThemeStore {
    struct Snapshot {
        let preset: Preset
        let baseFontSize: Double

        var font: Font {
            .system(size: baseFontSize)
        }
    }

    enum Preset: String, CaseIterable, Identifiable {
        case `default`
        case gitHub

        var id: String { rawValue }

        var title: String {
            switch self {
            case .default:
                return "Default"
            case .gitHub:
                return "GitHub"
            }
        }
    }

    var preset: Preset = .default
    var baseFontSize: Double = 16
    var previewTheme: PreviewTheme = .serif

    var font: Font {
        .system(size: baseFontSize)
    }

    var snapshot: Snapshot {
        Snapshot(preset: preset, baseFontSize: baseFontSize)
    }
}
