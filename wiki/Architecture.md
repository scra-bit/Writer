# Architecture Overview

Writer follows a clean, store-based architecture using SwiftUI and Apple's Observation framework. The app is designed around reactive state management with clear separation between UI components and business logic.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                           WriterApp (Entry Point)                   │
│  - App initialization                                              │
│  - Menu commands (File, Edit, View, Command Palette)              │
│  - Export handlers (HTML, PDF, RTF)                               │
│  - Store initialization (@State)                                   │
└──────────────┬──────────────────────────────────────────────────────┘
               │
               │ Environment injection
               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        ContentView (Main UI)                       │
│  - NavigationSplitView (Sidebar + Detail)                         │
│  - Sidebar: File tree with context menus                           │
│  - Detail: Editor + Preview layout                                │
│  - Toolbar: Save, Refresh, Preview toggle                         │
│  - Command Palette overlay                                        │
└──────────────┬──────────────────────────────────────────────────────┘
               │
               │ Reads from @Environment
               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         Store Layer                                │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ EditorStore │  │ ThemeStore   │  │ LayoutStore  │          │
│  │              │  │              │  │              │          │
│  │ - fileTree  │  │ - preset    │  │ - showPreview│          │
│  │ - document  │  │ - fontSize  │  └──────────────┘          │
│  │ - selected  │  │ - preview   │           ▲                  │
│  │ - expanded  │  │   Theme     │           │                  │
│  └──────────────┘  └──────────────┘  ┌──────────────┐          │
│        ▲                     ▲         │ CommandP-    │          │
│        │                     │         │ aletteStore  │          │
│        │                     │         │              │          │
│        │                     │         │ - isVisible  │          │
│        │                     │         │ - commands   │          │
│        │                     │         │ - searchText │          │
│        │                     │         └──────────────┘          │
└────────┼─────────────────────┼────────────────────────────────────┘
         │                     │
         │ Uses                │ Uses
         ▼                     ▼
┌─────────────────────┐ ┌──────────────────────────────────────────┐
│  FileManager       │ │  Rendering Pipeline                       │
│  - Security-scoped│ │                                           │
│    bookmarks      │ │  ┌────────────────┐  ┌────────────────┐  │
│  - File operations│ │  │ Markdown-     │  │ Markdown-      │  │
│  - Folder access  │ │  │ TextView      │  │ Renderer       │  │
│                       │  │ (NSTextView)  │  │ (Apple         │  │
└─────────────────────┘  │ - Syntax      │  │  Markdown)      │  │
                          │   highlighting│  │ - HTMLVisitor  │  │
                          │ - Content     │  │ - Content      │  │
                          │   blocks      │  │   blocks       │  │
                          └───────┬──────┘  └───────┬────────┘  │
                                  │                │               │
                                  ▼                ▼               │
                          ┌──────────────────────────────────┐    │
                          │          WebView                  │    │
                          │    (WKWebView for preview)        │    │
                          └──────────────────────────────────┘    │
                                                                   │
                          ┌──────────────────────────────────┐    │
                          │       Export Pipeline            │    │
                          │  ┌──────────┐ ┌──────────┐    │    │
                          │  │ HTML     │ │ PDF      │    │    │
                          │  │ Exporter │ │ Exporter│    │    │
                          │  └──────────┘ └──────────┘    │    │
                          │  ┌──────────┐                   │    │
                          │  │ RTF      │                   │    │
                          │  │ Exporter │                   │    │
                          │  └──────────┘                   │    │
                          └──────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────────┘
```

## State Management

Writer uses Apple's **Observation framework** with the `@Observable` macro for reactive state management. This modern approach replaces the older `ObservableObject`/`@Published` pattern with a more efficient, Swift-native solution.

### Observable Stores

All stores are marked with `@Observable` and are injected into the environment:

```swift
@Observable
final class EditorStore {
    // State properties (automatically tracked)
    var fileTree: [FileNode] = []
    var documentText = ""
    var selectedFileURL: URL?
    // ...
}
```

### Store Injection

Stores are created as `@State` in the app entry point and injected via environment:

```swift
@main
struct WriterApp: App {
    @State private var editorStore = EditorStore()
    @State private var themeStore = ThemeStore()
    @State private var layoutStore = LayoutStore()
    @State private var commandPaletteStore = CommandPaletteStore()

    var body: some Scene {
        Window("Writer", id: "main") {
            ContentView()
                .environment(editorStore)
                .environment(themeStore)
                .environment(layoutStore)
                .environment(commandPaletteStore)
        }
    }
}
```

### Reading State in Views

Views access stores using `@Environment`:

```swift
struct ContentView: View {
    @Environment(EditorStore.self) private var editorStore
    @Environment(ThemeStore.self) private var themeStore
    // ...
}
```

## Rendering Pipeline

The markdown rendering pipeline converts raw markdown text into rendered HTML for preview and export.

### Pipeline Flow

```
Markdown Text (String)
       │
       ▼
┌──────────────────────────────────┐
│     MarkdownRenderer             │
│                                  │
│  1. Parse content blocks        │
│     (ContentBlockSyntax)          │
│                                  │
│  2. Split into segments:         │
│     - .markdown(chunk)            │
│     - .contentBlock(resolved)     │
│                                  │
│  3. For markdown segments:        │
│     - Escape HTML entities        │
│     - Parse with Apple Markdown   │
│     - Visit with HTMLVisitor      │
│     - Process ==highlight==       │
│                                  │
│  4. For content blocks:           │
│     - Resolve file paths          │
│     - Classify block type         │
│     - Render appropriately        │
└──────────────┬───────────────────┘
               │
               ▼
        HTML String (body)
               │
               ▼
┌──────────────────────────────────┐
│       PreviewTheme                │
│                                  │
│  - Generates CSS from theme      │
│  - Wraps body in full HTML doc   │
│  - Includes @media print styles  │
└──────────────┬───────────────────┘
               │
               ▼
    WKWebView (for preview)
    OR
    Exporters (for export)
```

### Content Block Processing

Content blocks allow transcluding external files into the markdown document. The `ContentBlockSyntax` struct handles parsing and resolution:

1. **Parse**: Detect content block syntax in a line
2. **Resolve**: Convert path to absolute URL using document and workspace roots
3. **Classify**: Determine block type (markdown, code, table, image)
4. **Render**: Generate appropriate HTML for the block type

### Supported Content Block Types

| File Extension | Block Type | Rendering |
|---------------|------------|-----------|
| `.md`, `.markdown`, `.txt` | Transcluded Markdown | Rendered through markdown pipeline |
| `.csv` | Table (comma-delimited) | Rendered as HTML `<table>` |
| `.tsv` | Table (tab-delimited) | Rendered as HTML `<table>` |
| `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`, `.heic`, `.heif`, `.tif`, `.tiff` | Image | Embedded as base64 data URI |
| Code extensions (`.swift`, `.js`, `.py`, etc.) | Code Block | Wrapped in `<pre><code>` |

## Security-Scoped Bookmarks

Writer uses macOS security-scoped bookmarks to persist folder access across app launches without requiring user interaction each time.

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    First Launch                            │
│                                                             │
│  1. User selects folder via NSOpenPanel                     │
│  2. App creates bookmark with .withSecurityScope option    │
│  3. Bookmark data saved to UserDefaults                    │
│  4. App starts accessing security-scoped resource          │
│  5. Folder contents loaded                                 │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Subsequent Launches                      │
│                                                             │
│  1. App reads bookmark from UserDefaults                   │
│  2. Resolves bookmark to URL                               │
│  3. If stale, updates bookmark data                        │
│  4. Starts accessing security-scoped resource             │
│  5. Folder contents loaded (no user prompt)                │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

Located in `EditorStore.swift`:

```swift
// Creating a bookmark
let bookmarkData = try url.bookmarkData(
    options: .withSecurityScope,
    includingResourceValuesForKeys: nil,
    relativeTo: nil
)
UserDefaults.standard.set(bookmarkData, forKey: BookmarkKeys.folderBookmark)

// Resolving a bookmark
let url = try URL(
    resolvingBookmarkData: bookmarkData,
    options: .withSecurityScope,
    relativeTo: nil,
    bookmarkDataIsStale: &isStale
)

// Accessing the resource
securityScopedAccessToken = url.startAccessingSecurityScopedResource()

// Stop accessing when done (in deinit or before new selection)
url.stopAccessingSecurityScopedResource()
```

### Bookmark Key

The bookmark is stored in `UserDefaults` with the key: `forthewriting_folder_bookmark`

## Store Relationships

### EditorStore
**Purpose**: Central state management for file operations and document editing.

**Key Responsibilities**:
- File tree management (loading, refreshing, navigating)
- Document text and selection state
- File operations (create, rename, move, copy, paste, delete)
- Security-scoped bookmark management
- Autosave scheduling
- Table formatting

**Dependencies**: `Observation`, `AppKit`, `FileManager`

### ThemeStore
**Purpose**: Manages preview theme selection and typography settings.

**Key Responsibilities**:
- Theme preset selection (Default, GitHub)
- Base font size control
- Providing `PreviewTheme` for rendering
- Snapshot creation for state preservation

**Dependencies**: `Observation`, `SwiftUI`

### LayoutStore
**Purpose**: Manages UI layout state.

**Key Responsibilities**:
- Toggle preview visibility
- Simple boolean state for split view layout

**Dependencies**: `Observation`, `Foundation`

### CommandPaletteStore
**Purpose**: Manages command palette state and actions.

**Key Responsibilities**:
- Visibility state
- Command registration and filtering
- Search text and selection index
- Command execution

**Dependencies**: `Observation`, `SwiftUI`

## Data Flow Example: Editing a Document

```
User types in MarkdownTextView
         │
         ▼
NSTextViewDelegate.textDidChange()
         │
         ▼
MarkdownTextView.Coordinator.textDidChange()
         │
         ▼
Binding<String> updated
         │
         ▼
EditorStore.documentText changes
         │
         ├──► MarkdownTextView.applyMarkdownStyling() (syntax highlighting)
         │
         ├──► EditorStore.scheduleAutosave() (after 350ms delay)
         │         │
         │         └──► EditorStore.persistCurrentDocument()
         │                   │
         │                   └──► documentText.write(to: selectedFileURL)
         │
         └──► ContentView.onChange(of: documentText)
                   │
                   └──► WebView.updateNSView()
                             │
                             └──► MarkdownRenderer.renderBodyContent()
                                       │
                                       └──► WKWebView.loadHTMLString()
```

## Design Patterns

### Store Pattern
All business logic is encapsulated in `@Observable` classes, keeping views as thin as possible.

### Delegate Pattern
`NSTextViewDelegate` is used for the custom text view to monitor text changes.

### Coordinator Pattern
`NSViewRepresentable` uses a `Coordinator` class to bridge delegate callbacks to SwiftUI state.

### Builder Pattern
Export operations use a builder-like flow: configure → generate → save.

### Strategy Pattern
`ContentBlockSyntax` uses different strategies for parsing captions with different delimiters (quotes, parentheses).
