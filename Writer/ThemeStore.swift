//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
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

    private enum Keys {
        static let preset = "themePreset"
        static let baseFontSize = "baseFontSize"
    }

    var preset: Preset = .default {
        didSet { UserDefaults.standard.set(preset.rawValue, forKey: Keys.preset) }
    }
    var baseFontSize: Double = 16 {
        didSet { UserDefaults.standard.set(baseFontSize, forKey: Keys.baseFontSize) }
    }
    var previewTheme: PreviewTheme = .sansSerif

    init() {
        let savedPreset = UserDefaults.standard.string(forKey: Keys.preset) ?? Preset.default.rawValue
        self.preset = Preset(rawValue: savedPreset) ?? .default
        self.baseFontSize = UserDefaults.standard.object(forKey: Keys.baseFontSize) as? Double ?? 16
    }

    var font: Font {
        .system(size: baseFontSize)
    }

    var snapshot: Snapshot {
        Snapshot(preset: preset, baseFontSize: baseFontSize)
    }
}
