//
//  DesignTokens.swift
//  Writer
//
//   Writer is Copyright (C) 2026  Emmett Buck-Thompson and Contributors
//  Centralized design tokens for colors and typography
//  These tokens provide a single source of truth for all theme values
//

import Foundation

/// Design tokens providing a centralized source of truth for styling values
enum DesignTokens {
    
    // MARK: - Color Tokens
    
    enum Colors {
        // MARK: - Light Theme Colors
        
        enum Light {
            static let background = "#ffffff"
            static let text = "#24292e"
            static let link = "#0366d6"
            static let codeBackground = "#f6f8fa"
            static let border = "#e1e4e8"
            static let secondaryText = "#6a737d"
        }
        
        // MARK: - Dark Theme Colors (prepared for future use)
        
        enum Dark {
            static let background = "#0d1117"
            static let text = "#c9d1d9"
            static let link = "#58a6ff"
            static let codeBackground = "#161b22"
            static let border = "#30363d"
            static let secondaryText = "#8b949e"
        }
        
        // MARK: - Convenience accessors
        
        static func backgroundColor(for scheme: ColorScheme = .light) -> String {
            switch scheme {
            case .light: return Light.background
            case .dark: return Dark.background
            }
        }
        
        static func textColor(for scheme: ColorScheme = .light) -> String {
            switch scheme {
            case .light: return Light.text
            case .dark: return Dark.text
            }
        }
        
        static func linkColor(for scheme: ColorScheme = .light) -> String {
            switch scheme {
            case .light: return Light.link
            case .dark: return Dark.link
            }
        }
        
        static func codeBackgroundColor(for scheme: ColorScheme = .light) -> String {
            switch scheme {
            case .light: return Light.codeBackground
            case .dark: return Dark.codeBackground
            }
        }
        
        static func borderColor(for scheme: ColorScheme = .light) -> String {
            switch scheme {
            case .light: return Light.border
            case .dark: return Dark.border
            }
        }
        
        static func secondaryTextColor(for scheme: ColorScheme = .light) -> String {
            switch scheme {
            case .light: return Light.secondaryText
            case .dark: return Dark.secondaryText
            }
        }
    }
    
    // MARK: - Typography Tokens
    
    enum Typography {
        // MARK: - Font Families
        
        enum FontFamilies {
            // Sans Serif (system default)
            static let sansSerifBody = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif"
            static let sansSerifHeading = "system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
            static let sansSerifCode = "'SF Mono', Menlo, Monaco, 'Courier New', monospace"
            
            // Serif
            static let serifBody = "Georgia, 'Times New Roman', Times, serif"
            static let serifHeading = "Georgia, 'Times New Roman', Times, serif"
            static let serifCode = "'SF Mono', Menlo, Monaco, 'Courier New', monospace"
        }
        
        // MARK: - Font Sizes
        
        enum FontSizes {
            static let base: Int = 16
            static let heading1: Double = 2.0      // 2em
            static let heading2: Double = 1.5      // 1.5em
            static let heading3: Double = 1.25     // 1.25em
            static let heading4: Double = 1.0      // 1em
            static let heading5: Double = 0.875    // 0.875em
            static let heading6: Double = 0.85     // 0.85em
            static let code: Double = 0.85         // 85%
            static let codeBlock: Double = 0.85    // 85%
        }
        
        // MARK: - Line Heights
        
        enum LineHeights {
            static let body: Double = 1.6
            static let heading: Double = 1.25
            static let codeBlock: Double = 1.45
        }
        
        // MARK: - Spacing
        
        enum Spacing {
            static let xs: Int = 4
            static let sm: Int = 8
            static let md: Int = 16
            static let lg: Int = 24
            static let xl: Int = 32
        }
    }
    
    // MARK: - Color Scheme
    
    enum ColorScheme {
        case light
        case dark
    }
}

// MARK: - Convenience Type Aliases

typealias ColorScheme = DesignTokens.ColorScheme
