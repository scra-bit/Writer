# Writer Wiki

Welcome to the Writer documentation wiki. Writer is a distraction-free text editor for macOS, built with SwiftUI, that provides a seamless markdown editing experience with live preview and export capabilities.

## Quick Links

| Page | Description |
|------|-------------|
| [Architecture](Architecture.md) | System architecture and design patterns |
| [Components](Components.md) | Detailed component documentation |
| [Features](Features.md) | Feature documentation and usage |
| [Build and Deploy](Build-and-Deploy.md) | Build instructions and CI/CD setup |
| [Keyboard Shortcuts](Keyboard-Shortcuts.md) | Complete shortcut reference |
| [Content Blocks](Content-Blocks.md) | Content block syntax specification |
| [Testing](Testing.md) | Testing guide and coverage |

## Key Features

### Markdown Editing
- **Syntax Highlighting**: Real-time markdown syntax highlighting with support for headings, bold, italic, strikethrough, and highlights
- **Content Blocks**: Transclude external files, tables, code, and images directly in your documents
- **Table Formatting**: Automatic formatting and alignment detection for markdown tables

### Live Preview
- **Real-time Rendering**: See your markdown rendered as you type
- **Theme Support**: Choose between Sans Serif and Serif preview themes
- **Customizable Typography**: Adjust base font size to suit your preferences

### Export Capabilities
- **HTML Export**: Standalone HTML files with inline CSS styling
- **PDF Export**: Print-optimized PDF with proper pagination
- **RTF Export**: Rich Text Format for compatibility with other editors

### File Management
- **Folder-Based Workflow**: Select a workspace folder and navigate your file hierarchy
- **Security-Scoped Bookmarks**: Persists folder access across app launches
- **File Operations**: Create, rename, move, copy, and delete files and folders
- **Drag and Drop**: Reorganize files by dragging them in the sidebar

### Productivity Features
- **Command Palette**: Quick access to all commands (⌘⇧P)
- **Auto-Save**: Automatic saving as you type
- **Format Tables**: Instantly format messy markdown tables (⌘⇧F)

## Getting Started

### Prerequisites
- macOS 13.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Building from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Writer.git
   cd Writer
   ```

2. Open in Xcode:
   ```bash
   open Writer.xcodeproj
   ```

3. Build and run:
   - Select the `Writer` scheme
   - Press ⌘R to build and run

### First Launch

On first launch, Writer will prompt you to select a writing folder. This folder becomes your workspace, and Writer will:
- Display all markdown and text files in the sidebar
- Watch for file changes and refresh automatically
- Remember your selection across app launches using security-scoped bookmarks

## Project Structure

```
Writer/
├── Writer/                 # Main application code
│   ├── WriterApp.swift              # App entry point
│   ├── ContentView.swift            # Main UI
│   ├── EditorStore.swift            # Document state management
│   ├── ThemeStore.swift             # Theme and typography state
│   ├── LayoutStore.swift            # Layout state (preview toggle)
│   ├── CommandPaletteStore.swift    # Command palette state
│   ├── MarkdownRenderer.swift      # Markdown to HTML conversion
│   ├── WebView.swift               # WKWebView wrapper for preview
│   ├── MarkdownTextView.swift      # Custom NSTextView with syntax highlighting
│   ├── PreviewTheme.swift          # Theme definitions with CSS generation
│   ├── HTMLExporter.swift          # HTML export functionality
│   ├── PDFExporter.swift           # PDF export via NSPrintOperation
│   ├── RTFExporter.swift          # RTF export via NSAttributedString
│   ├── TableFormatter.swift        # Markdown table formatting
│   ├── DesignTokens.swift          # Centralized design tokens
│   └── ThemeEditorView.swift      # Theme customization UI
├── WriterTests/             # Unit tests
└── .github/workflows/      # CI/CD configuration
```

## Technical Overview

Writer is built entirely in SwiftUI using Apple's Observation framework for state management. The app follows a store-based architecture where `@Observable` classes manage different aspects of application state.

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **Observation Framework**: `@Observable` macro for reactive state management
- **Apple Markdown Framework**: Native markdown parsing and rendering
- **WKWebView**: Web-based preview rendering
- **NSTextView**: Custom text editing with syntax highlighting

### Bundle Information
- **Bundle ID**: `EmmettBuckThompson.Writer`
- **Minimum macOS Version**: 13.0
- **Swift Language Version**: 5.0+

## Contributing

Writer is an open-source project and welcomes contributions. Please see the [Build and Deploy](Build-and-Deploy.md) guide for information on building the project and running tests.

## License

Writer is released under the GPLv3 License. See [LICENSE.md](../LICENSE.md) for details.

---

*For detailed technical documentation, explore the pages linked above.*
