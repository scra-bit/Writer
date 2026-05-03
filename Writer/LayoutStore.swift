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
    }

    var showPreview: Bool = false {
        didSet { UserDefaults.standard.set(showPreview, forKey: Keys.showPreview) }
    }

    init() {
        self.showPreview = UserDefaults.standard.bool(forKey: Keys.showPreview)
    }
}
