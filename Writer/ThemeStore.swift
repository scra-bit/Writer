//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//  ThemeStore.swift
//  Writer
//
//
//

import Observation
import SwiftUI

extension NSAppearance {
    /// Checks whether this effective appearance resolves to dark Aqua.
    var isDarkMode: Bool {
        bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
}

extension NSView {
    /// Returns whether the view's effective appearance resolves to dark Aqua.
    var isDarkMode: Bool {
        effectiveAppearance.isDarkMode
    }
}

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

    enum PreviewColorScheme: String, CaseIterable {
        case light
        case dark
        case system

        var title: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .system: return "System"
            }
        }
    }

    private enum Keys {
        static let preset = "themePreset"
        static let baseFontSize = "baseFontSize"
        static let previewColorScheme = "previewColorScheme"
    }

    var preset: Preset = .default {
        didSet { UserDefaults.standard.set(preset.rawValue, forKey: Keys.preset) }
    }
    var baseFontSize: Double = 16 {
        didSet { UserDefaults.standard.set(baseFontSize, forKey: Keys.baseFontSize) }
    }
    var previewColorScheme: PreviewColorScheme = .system {
        didSet {
            UserDefaults.standard.set(previewColorScheme.rawValue, forKey: Keys.previewColorScheme)
        }
    }

    init() {
        let savedPreset =
            UserDefaults.standard.string(forKey: Keys.preset) ?? Preset.default.rawValue
        self.preset = Preset(rawValue: savedPreset) ?? .default
        self.baseFontSize = UserDefaults.standard.object(forKey: Keys.baseFontSize) as? Double ?? 16
        if let savedScheme = UserDefaults.standard.string(forKey: Keys.previewColorScheme) {
            self.previewColorScheme = PreviewColorScheme(rawValue: savedScheme) ?? .system
        }
    }

    /// Returns the appropriate preview theme based on the selected color scheme
    var previewTheme: PreviewTheme {
        let useDark: Bool
        switch previewColorScheme {
        case .light: useDark = false
        case .dark: useDark = true
        case .system: useDark = NSApp.effectiveAppearance.isDarkMode
        }

        // For now, we only have sans-serif themes - gitHub variant can be added later
        return useDark ? .sansSerifDark : .sansSerifLight
    }

    var font: Font {
        .system(size: baseFontSize)
    }

    var snapshot: Snapshot {
        Snapshot(preset: preset, baseFontSize: baseFontSize)
    }
}
