////   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//  LayoutStore.swift
//  Writer
//

import Foundation
import Observation

@MainActor
@Observable
final class LayoutStore {
    private enum Keys {
        static let showPreview = "showPreview"
        static let showLineNumbers = "forthewriting_editor_showLineNumbers"
    }

    var showPreview: Bool = false {
        didSet { UserDefaults.standard.set(showPreview, forKey: Keys.showPreview) }
    }

    var showLineNumbers: Bool = true {
        didSet { UserDefaults.standard.set(showLineNumbers, forKey: Keys.showLineNumbers) }
    }

    init() {
        self.showPreview = UserDefaults.standard.bool(forKey: Keys.showPreview)
        // Default the gutter on for first launch (no stored value).
        self.showLineNumbers =
            UserDefaults.standard.object(forKey: Keys.showLineNumbers) as? Bool ?? true
    }
}
