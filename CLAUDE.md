# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Writer is a distraction-free text editor for macOS, built with SwiftUI. It provides a markdown editing experience with live preview and HTML export capabilities.

## Build & Run

- **Open in Xcode**: `open Writer.xcodeproj`
- **Build**: Product → Build (⌘B)
- **Run**: Product → Run (⌘R)

## Architecture

The app uses SwiftUI with the Observation framework for state management.

### Key Components

- **EditorStore** (`EditorStore.swift`): Central @Observable class managing file selection, document state, autosave, and file tree navigation. Uses security-scoped bookmarks to persist folder access across app launches.

- **ThemeStore** (`ThemeStore.swift`): @Observable class managing preview themes and typography settings. Provides presets and font size control.

- **WebView** (`WebView.swift`): SwiftUI wrapper around WKWebView that renders markdown to HTML using Apple's `Markdown` framework. Includes a custom `HTMLVisitor` to convert Markdown AST to HTML.

- **HTMLExporter** (`HTMLExporter.swift`): Standalone HTML generation from markdown with theme styling. Uses the same rendering pipeline as WebView.

- **PreviewTheme** (`PreviewTheme.swift`): Defines color palettes and typography for the preview pane. Generates inline CSS for HTML export.

- **ContentView** (`ContentView.swift`): Main UI with NavigationSplitView - sidebar for file tree, detail pane with split editor/preview.

- **WriterApp** (`WriterApp.swift`): App entry point with menu commands for file creation and HTML export.

### Key Design Patterns

- **@Observable**: All state management uses Swift's Observation framework
- **Environment**: EditorStore and ThemeStore passed via SwiftUI environment
- **Markdown Rendering**: Uses Apple's `Markdown` framework with custom `MarkupVisitor` for HTML generation
- **Security-Scoped Bookmarks**: Persists folder access using `URL.bookmarkData(options: .withSecurityScope)`

## File Types

The editor supports: `.md`, `.markdown`, `.txt`, `.text` files.

## Keyboard Shortcuts

- ⌘N: New file
- ⌘⇧N: New folder
- ⌘⇧E: Export to HTML