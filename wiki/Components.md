# Components Documentation

This page provides detailed documentation for all Swift files in the Writer codebase, organized by category.

## Core Components

### WriterApp.swift
**Location**: `Writer/WriterApp.swift`  
**Purpose**: Application entry point and menu configuration

**Key Responsibilities**:
- Initializes all store instances as `@State`
- Configures menu commands (File, Edit, View, Command Palette)
- Sets up export handlers for HTML, PDF, and RTF
- Configures command palette actions
- Manages export error/success state

**Dependencies**:
- `EditorStore` - Document and file management
- `ThemeStore` - Theme and typography settings
- `LayoutStore` - Preview layout state
- `CommandPaletteStore` - Command palette state

**Usage**:
```swift
@main
struct WriterApp: App {
    @State private var editorStore = EditorStore()
    @State private var themeStore = ThemeStore()
    // ...
}
```

**Menu Commands Configured**:
- File: New File (⌘N), New Folder (⌘⇧N), Export options, Format Tables
- Edit: Undo, Redo, Cut, Copy, Paste, Select All
- View: Toggle Preview (⌘/)
- Command Palette: Show (⌘⇧P)

---

### EditorStore.swift
**Location**: `Writer/EditorStore.swift`  
**Purpose**: Central @Observable state management for files and documents

**Key Responsibilities**:
- File tree management (loading, refreshing, navigating)
- Document text and selection state
- File operations (create, rename, move, copy, paste, delete, duplicate)
- Security-scoped bookmark management for persistent folder access
- Autosave scheduling (350ms debounce)
- Table formatting integration

**Dependencies**:
- `Observation` framework
- `AppKit` (NSAlert, NSWorkspace, NSPasteboard)
- `FileManager` for file operations

**Key Properties**:
```swift
var rootURL: URL?                    // Root folder URL
var fileTree: [FileNode]             // Hierarchical file structure
var selectedFileURL: URL?              // Currently selected file
var documentText = ""                 // Current document content
var errorMessage: String?              // Error state
var expandedIDs: Set<URL>             // Expanded folder tracking
```

**Key Methods**:
- `refreshFiles()` - Reloads file tree from disk
- `selectFile(at:)` - Opens a file for editing
- `persistCurrentDocument()` - Saves current document
- `scheduleAutosave()` - Debounced auto-save
- `createFile(named:extension:)` - Creates new file
- `createFolder(named:)` - Creates new folder
- `renameItem(_:to:)` - Renames file/folder
- `deleteItem(_:)` - Moves item to trash
- `moveItem(_:to:)` - Moves item to new location
- `copyItems(_:)`, `cutItems(_:)`, `pasteItems(to:)` - Clipboard operations
- `formatAllTables()` - Formats all markdown tables in document

**Structs**:
- `FileNode`: Identifiable, Hashable struct representing a file or folder
- `PendingCreation`: Enum for new file/folder creation flow

---

### ThemeStore.swift
**Location**: `Writer/ThemeStore.swift`  
**Purpose**: Manages preview theme and typography settings

**Key Responsibilities**:
- Theme preset selection (Default, GitHub)
- Base font size control
- Providing `PreviewTheme` instance for rendering
- Snapshot creation for state preservation

**Dependencies**:
- `Observation` framework
- `SwiftUI` (Font type)

**Key Properties**:
```swift
var preset: Preset = .default         // Theme preset
var baseFontSize: Double = 16         // Base font size in points
var previewTheme: PreviewTheme = .sansSerif  // Current theme
```

**Presets**:
```swift
enum Preset: String, CaseIterable {
    case `default`  // "Default" theme
    case gitHub     // "GitHub" theme
}
```

**Snapshot**:
```swift
struct Snapshot {
    let preset: Preset
    let baseFontSize: Double
    var font: Font { .system(size: baseFontSize) }
}
```

---

### LayoutStore.swift
**Location**: `Writer/LayoutStore.swift`  
**Purpose**: Manages UI layout state

**Key Responsibilities**:
- Toggle preview visibility
- Store preview layout preference

**Dependencies**:
- `Observation` framework
- `Foundation`

**Key Properties**:
```swift
var showPreview = false  // Controls preview pane visibility
```

**Usage**: Bound to `Binding` in ContentView to toggle HSplitView visibility.

---

### CommandPaletteStore.swift
**Location**: `Writer/CommandPaletteStore.swift`  
**Purpose**: Manages command palette state and actions

**Key Responsibilities**:
- Visibility state management
- Command registration and storage
- Search text filtering
- Selected index tracking
- Command execution

**Dependencies**:
- `Observation` framework
- `SwiftUI` (EventModifiers)

**Key Structures**:
```swift
struct Command: Identifiable {
    let id: String
    let title: String
    let keyEquivalent: String
    let modifiers: EventModifiers
    var action: () -> Void
}
```

**Key Properties**:
```swift
var isVisible = false
var searchText = ""
var selectedIndex = 0
var commands: [Command] = [...]  // Pre-configured commands
var filteredCommands: [Command]   // Filtered by searchText
```

**Key Methods**:
- `show()` - Display palette, reset search
- `hide()` - Dismiss palette
- `toggle()` - Toggle visibility
- `moveSelection(by:)` - Navigate up/down in list
- `executeSelected()` - Run selected command
- `execute(id:)` - Run command by ID
- `setAction(for:action:)` - Update command action

---

## Rendering Components

### MarkdownRenderer.swift
**Location**: `Writer/MarkdownRenderer.swift`  
**Purpose**: Converts markdown to HTML with content block support

**Key Responsibilities**:
- Parse and render markdown using Apple's Markdown framework
- Process content blocks (transclusion, tables, code, images)
- Generate HTML with proper escaping
- Handle highlight syntax (`==text==`)
- Recursive content block resolution with cycle detection

**Dependencies**:
- `Markdown` framework (Apple)
- `AppKit` (NSRegularExpression)
- `Foundation`

**Key Structures**:

**MarkdownRenderContext**:
```swift
struct MarkdownRenderContext {
    let documentURL: URL?           // Current document URL
    let workspaceRootURL: URL?       // Workspace root URL
}
```

**ContentBlockSyntax**:
```swift
struct ContentBlockSyntax {
    struct ContentBlockMatch {
        let path: String
        let caption: String?
        let captionStyle: CaptionStyle?
        let originalLine: String
    }
    
    struct ResolvedContentBlock {
        let match: ContentBlockMatch
        let url: URL?
    }
    
    enum CaptionStyle {
        case doubleQuoted   // "Caption"
        case singleQuoted   // 'Caption'
        case parenthesized  // (Caption)
    }
    
    static func parseLine(_ line: String) -> ContentBlockMatch?
    static func resolve(_ match: ContentBlockMatch, context: MarkdownRenderContext) -> ResolvedContentBlock
}
```

**HTMLVisitor**:
Custom `MarkupVisitor` implementation that converts Markdown AST to HTML:
- Visits all standard markdown elements (headings, paragraphs, emphasis, etc.)
- Handles tables, code blocks, links, images
- Properly escapes HTML entities

**MarkdownRenderer** (struct):
```swift
struct MarkdownRenderer {
    static func renderBodyContent(_ markdown: String, context: MarkdownRenderContext) -> String
    static func escapeHTMLEntities(_ text: String) -> String
    static func wrapInHTMLDocument(_ bodyContent: String, theme: PreviewTheme) -> String
}
```

**Content Block Types** (private enum):
- `.transcludedMarkdown` - .md, .markdown, .txt files
- `.code(language:)` - Source code files
- `.table(delimiter:)` - .csv (comma), .tsv (tab)
- `.image(mimeType:)` - Image files
- `.unsupported` - Unknown file types

---

### HTMLVisitor.swift (within MarkdownRenderer.swift)
**Purpose**: Custom MarkupVisitor for generating HTML from Markdown AST

**Visited Elements**:
- Document, Paragraph, Text
- Heading (h1-h6), Emphasis, Strong, Strikethrough
- InlineCode, CodeBlock
- Link, Image
- List (ordered/unordered), ListItem
- BlockQuote, Table, TableHead, TableBody, TableRow, TableCell
- ThematicBreak, SoftBreak, LineBreak

**Key Methods**:
```swift
mutating func visitHeading(_ heading: Heading) -> String
mutating func visitParagraph(_ paragraph: Paragraph) -> String
mutating func visitStrong(_ strong: Strong) -> String
mutating func visitEmphasis(_ emphasis: Emphasis) -> String
// ... and more for each markdown element
```

---

### WebView.swift
**Location**: `Writer/WebView.swift`  
**Purpose**: SwiftUI wrapper around WKWebView for live preview

**Key Responsibilities**:
- Display rendered HTML in a web view
- Theme selection via dropdown menu (bottom-right overlay)
- Update preview when markdown or theme changes

**Dependencies**:
- `SwiftUI`
- `WebKit` (WKWebView, WKWebViewConfiguration)
- `Observation`

**Components**:

**WebView** (SwiftUI View):
```swift
struct WebView: View {
    let markdown: String
    let theme: PreviewTheme
    let renderContext: MarkdownRenderContext
}
```

**WebViewRepresentable** (NSViewRepresentable):
```swift
struct WebViewRepresentable: NSViewRepresentable {
    let markdown: String
    let theme: PreviewTheme
    let renderContext: MarkdownRenderContext
    
    func makeNSView(context: Context) -> WKWebView
    func updateNSView(_ webView: WKWebView, context: Context)
}
```

**Features**:
- Developer extras enabled (for debugging)
- White background forced
- Theme selector overlay at bottom-right
- Automatic re-rendering on markdown/theme change

---

### MarkdownTextView.swift
**Location**: `Writer/MarkdownTextView.swift`  
**Purpose**: Custom NSTextView with syntax highlighting

**Key Responsibilities**:
- Display and edit markdown text
- Real-time syntax highlighting
- Content block visual indication
- Proper font and paragraph styling
- Delegate integration with SwiftUI bindings

**Dependencies**:
- `SwiftUI`
- `AppKit` (NSTextView, NSFont, NSAttributedString)
- `Observation`

**Components**:

**MarkdownTextView** (NSViewRepresentable):
```swift
struct MarkdownTextView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat = 16
    var documentURL: URL?
    var workspaceRootURL: URL?
}
```

**MarkdownTextViewInternal** (NSTextView subclass):
```swift
class MarkdownTextViewInternal: NSTextView {
    var renderContext = MarkdownRenderContext()
    
    func applyMarkdownStyling()           // Apply syntax highlighting
    func applyBaseTypingAttributes()      // Reset typing attributes
}
```

**Syntax Highlighting** (Regex-based):
- Headings: `# Heading` (bold + indent)
- Bold: `**text**` or `__text__` (bold font)
- Italic: `*text*` or `_text_` (italic font)
- Bold-Italic: `***text***` or `___text___` (bold + italic)
- Strikethrough: `~~text~~` (strikethrough + secondary color)
- Highlight: `==text==` (yellow background)
- Content Blocks: Special color (blue if valid, orange if missing)

**Cached Regexes** (static to avoid recompilation):
```swift
private static let headingRegex
private static let boldItalicRegex
private static let boldRegex
private static let italicRegex
private static let strikethroughRegex
private static let highlightRegex
```

---

## Export Components

### HTMLExporter.swift
**Location**: `Writer/HTMLExporter.swift`  
**Purpose**: Exports markdown as standalone HTML files

**Key Responsibilities**:
- Generate complete HTML document with inline CSS
- Present NSSavePanel for file location selection
- Write HTML to disk

**Dependencies**:
- `Foundation`
- `Markdown` framework
- `AppKit` (NSSavePanel)
- `UniformTypeIdentifiers`

**API**:
```swift
struct HTMLExporter {
    let markdown: String
    let theme: PreviewTheme
    let renderContext: MarkdownRenderContext
    
    init(markdown: String, theme: PreviewTheme, renderContext: MarkdownRenderContext)
    
    func generateHTML() -> String
    func save(suggestedName: String) async throws -> URL
}
```

**Export Process**:
1. Call `MarkdownRenderer.renderBodyContent()` to get body HTML
2. Call `MarkdownRenderer.wrapInHTMLDocument()` to create full document
3. Present save panel with `.html` content type
4. Write string to selected URL

---

### PDFExporter.swift
**Location**: `Writer/PDFExporter.swift`  
**Purpose**: Exports markdown as paginated PDF using WebKit's print pipeline

**Key Responsibilities**:
- Render markdown to paginated PDF
- Use NSPrintOperation for proper multi-page output
- Respect `@media print` CSS rules
- Handle WKNavigationDelegate callbacks

**Dependencies**:
- `AppKit` (NSPrintInfo, NSPrintOperation, NSWindow)
- `WebKit` (WKWebView, WKNavigationDelegate)
- `UniformTypeIdentifiers`

**API**:
```swift
@MainActor
class PDFExporter: NSObject, WKNavigationDelegate {
    let markdown: String
    let theme: PreviewTheme
    let renderContext: MarkdownRenderContext
    
    init(markdown: String, theme: PreviewTheme, renderContext: MarkdownRenderContext)
    
    func generatePDF() async throws -> Data
    func save(suggestedName: String) async throws -> URL
}
```

**PDF Generation Process**:
1. Create WKWebView with US Letter frame (612×792 points)
2. Force light appearance for consistent output
3. Load HTML string
4. Wait for `webView(_:didFinish:)` delegate callback
5. Configure NSPrintInfo with 1-inch margins
6. Use `webView.printOperation(with:)` to create print operation
7. Direct output to temporary PDF file
8. Read PDF data from temp file
9. Clean up temp file

**Note**: Uses `NSPrintOperation` (not `WKWebView.createPDF`) for proper pagination.

---

### RTFExporter.swift
**Location**: `Writer/RTFExporter.swift`  
**Purpose**: Exports markdown as Rich Text Format (RTF)

**Key Responsibilities**:
- Convert markdown to HTML first
- Convert HTML to NSAttributedString
- Export as RTF data
- Present NSSavePanel for file location

**Dependencies**:
- `Foundation`
- `AppKit` (NSAttributedString, NSSavePanel)
- `UniformTypeIdentifiers`

**API**:
```swift
@MainActor
struct RTFExporter {
    let markdown: String
    let theme: PreviewTheme
    let renderContext: MarkdownRenderContext
    
    init(markdown: String, theme: PreviewTheme, renderContext: MarkdownRenderContext)
    
    func save(suggestedName: String) async throws -> URL
}
```

**Export Process**:
1. Generate HTML from markdown (same as HTML export)
2. Convert HTML string to NSAttributedString
3. Extract RTF data using `attributedString.rtf(from:documentAttributes:)`
4. Present save panel with `.rtf` content type
5. Write RTF data to selected URL

---

## Utility Components

### PreviewTheme.swift
**Location**: `Writer/PreviewTheme.swift`  
**Purpose**: Defines preview themes with typography and color palette

**Key Responsibilities**:
- Store theme properties (fonts, colors, sizes)
- Generate CSS styles from theme values
- Provide predefined theme instances

**Dependencies**:
- `Foundation`

**Theme Structure**:
```swift
struct PreviewTheme: Hashable {
    let name: String
    
    // Typography
    let bodyFontFamily: String
    let headingFontFamily: String
    let codeFontFamily: String
    let baseFontSize: Int
    let lineHeight: Double
    
    // Colors
    let backgroundColor: String
    let textColor: String
    let linkColor: String
    let codeBackgroundColor: String
    let borderColor: String
    let secondaryTextColor: String
    
    var cssStyles: String  // Generated CSS
}
```

**Predefined Themes**:
- `PreviewTheme.sansSerif` - "Sans Serif" theme (default)
- `PreviewTheme.serif` - "Serif" theme
- `PreviewTheme.allThemes` - Array of all available themes

**CSS Generation**:
The `cssStyles` property generates complete CSS including:
- Base body styles
- Heading styles (h1-h6)
- Code and preformatted text
- Links, blockquotes, lists
- Tables
- Content block styles
- Print-optimized styles (`@media print`)

---

### TableFormatter.swift
**Location**: `Writer/TableFormatter.swift`  
**Purpose**: Handles markdown table detection, parsing, and formatting

**Key Responsibilities**:
- Detect markdown tables in text
- Parse table rows and delimiter rows
- Calculate optimal column widths
- Detect column alignment (left, right, center)
- Format tables with proper padding
- Handle Unicode/CJK character widths

**Dependencies**:
- `Foundation`

**Key Types**:

**ColumnAlignment**:
```swift
enum ColumnAlignment: Equatable {
    case left, center, right, none
}
```

**TableColumn**:
```swift
struct TableColumn {
    let width: Int
    let alignment: ColumnAlignment
}
```

**API**:
```swift
struct TableFormatter {
    func detectTableRanges(in text: String) -> [(range: Range<String.Index>, lines: [String])]
    func isTableRow(_ line: String) -> Bool
    func isDelimiterRow(_ line: String) -> Bool
    func parseTableRow(_ row: String) -> [String]
    func calculateColumnWidths(rows: [[String]]) -> [TableColumn]
    func formatCell(_ content: String, width: Int, alignment: ColumnAlignment) -> String
    func formatTable(_ lines: [String]) -> String
    func formatEntireDocument(_ text: String) -> String
}
```

**Visual Width Calculation**:
Accounts for wide Unicode characters (CJK, emoji) that occupy 2 visual positions:
```swift
private func visualWidth(of string: String) -> Int
private func isWideCharacter(_ scalar: Unicode.Scalar) -> Bool
```

**Alignment Detection**:
Parses delimiter row (e.g., `|:---|---:|---|`) to determine column alignment.

---

### DesignTokens.swift
**Location**: `Writer/DesignTokens.swift`  
**Purpose**: Centralized design tokens for colors and typography

**Key Responsibilities**:
- Single source of truth for theme values
- Light and dark theme color definitions
- Typography settings (font families, sizes, line heights)
- Spacing values

**Dependencies**:
- `Foundation`

**Structure**:
```swift
enum DesignTokens {
    enum Colors {
        enum Light { ... }      // Light theme colors
        enum Dark { ... }       // Dark theme colors
        
        static func backgroundColor(for scheme: ColorScheme) -> String
        static func textColor(for scheme: ColorScheme) -> String
        // ... convenience accessors
    }
    
    enum Typography {
        enum FontFamilies { ... }
        enum FontSizes { ... }
        enum LineHeights { ... }
        enum Spacing { ... }
    }
    
    enum ColorScheme {
        case light, dark
    }
}
```

**Note**: Currently, `PreviewTheme` uses hardcoded values. `DesignTokens` is prepared for future use when theming is expanded.

---

### Content-Blocks.md (Documentation)
**Location**: `../Content-Blocks.md` (wiki page)  
**Purpose**: Documents the content block syntax specification

See the [Content Blocks](Content-Blocks.md) wiki page for full details.

---

## UI Components

### ContentView.swift
**Location**: `Writer/ContentView.swift`  
**Purpose**: Main application UI with NavigationSplitView

**Key Responsibilities**:
- Display sidebar with file tree
- Show editor and preview in split layout
- Handle file selection and navigation
- Provide toolbar buttons (save, refresh, preview toggle)
- Display command palette overlay
- Handle drag-and-drop for file reorganization
- Context menus for file operations

**Dependencies**:
- `SwiftUI`
- `EditorStore`, `ThemeStore`, `LayoutStore`, `CommandPaletteStore`

**UI Structure**:
```
NavigationSplitView
├── Sidebar
│   ├── File tree (List with FileNode rows)
│   ├── Context menus (folder/file operations)
│   ├── Drag and drop support
│   └── Error message overlay
└── Detail
    ├── Editor (MarkdownTextView)
    └── Preview (WebView)
        └── Split view controlled by LayoutStore.showPreview
```

**Key State**:
```swift
@State private var creationName = ""           // New file/folder name
@State private var renamingURL: URL?           // URL being renamed
@State private var renamingText = ""           // Rename text field
@State private var dropTargetURL: URL?         // Current drop target
```

**Sheet Presentation**:
- Creation sheet for new file/folder (`editorStore.pendingCreation`)

---

### CommandPaletteView.swift
**Location**: `Writer/CommandPaletteView.swift`  
**Purpose**: UI for the command palette overlay

**Key Responsibilities**:
- Search field with filtering
- Scrollable list of matching commands
- Keyboard navigation (up/down arrows, return, escape)
- Visual indication of selected command
- Keyboard shortcut display

**Dependencies**:
- `SwiftUI`
- `CommandPaletteStore`

**Components**:

**CommandPaletteView**:
```swift
struct CommandPaletteView: View {
    @Environment(CommandPaletteStore.self) private var store
    @FocusState private var isSearchFocused: Bool
}
```

**CommandRowView**:
```swift
struct CommandRowView: View {
    let command: Command
    let isSelected: Bool
}
```

**Keyboard Shortcuts** (invisible buttons):
- Up Arrow: Move selection up
- Down Arrow: Move selection down
- Return: Execute selected command
- Escape: Hide palette

**Features**:
- Animated show/hide (scale and opacity)
- Auto-focus search field on appear
- Scroll to selected item
- Clear button for search field
- Shortcut pills showing key equivalents

---

### ThemeEditorView.swift
**Location**: `Writer/ThemeEditorView.swift`  
**Purpose**: Simple UI for theme customization

**Key Responsibilities**:
- Theme preset picker (Picker)
- Base font size adjustment (TextField with number formatter)

**Dependencies**:
- `SwiftUI`
- `ThemeStore`

**UI**:
```swift
Form {
    Picker("Typography", selection: $themeStore.previewTheme) {
        ForEach(PreviewTheme.allThemes) { theme in
            Text(theme.name).tag(theme)
        }
    }
    
    HStack {
        Text("Base Font Size")
        Spacer()
        TextField("Size", value: $themeStore.baseFontSize, format: .number.precision(.fractionLength(0)))
        Text("pt")
    }
}
```

**Note**: This is a minimal theme editor. Future enhancements could include custom color picking and font selection.

---

## Test Components

### WriterTests/ Directory

Test files are located in `WriterTests/` and use the XCTest framework.

#### EditorStoreTests.swift
**Location**: `WriterTests/EditorStoreTests.swift`  
**Purpose**: Unit tests for EditorStore

**Test Cases**:
- `testRefreshFilesFiltersFilesAndSelectsFirstEditableFile()` - Verifies file filtering and auto-selection
- `testPersistCurrentDocumentWritesChangesToDisk()` - Tests document saving
- `testCreateRenameMoveAndPasteItemsUpdateWorkspace()` - Tests file operations

**Helper Methods**:
- `makeTemporaryWorkspace()` - Creates isolated test directory

---

#### MarkdownRendererTests.swift
**Location**: `WriterTests/MarkdownRendererTests.swift`  
**Purpose**: Unit tests for MarkdownRenderer

**Test Cases**:
- `testRenderBodyContentEscapesHTMLAndRendersMarkdown()` - Verifies HTML escaping and markdown rendering
- `testRenderBodyContentProcessesHighlightSyntax()` - Tests `==highlight==` processing
- `testWrapInHTMLDocumentIncludesThemeCSSAndBodyContent()` - Verifies HTML document structure
- `testRenderBodyContentTranscludesMarkdownContentBlocks()` - Tests content block transclusion
- `testRenderBodyContentShowsWarningForMissingContentBlock()` - Tests warning block rendering
- `testRenderBodyContentRendersCSVContentBlocksAsTable()` - Tests CSV table rendering
- `testRenderBodyContentDoesNotTreatPlainFilenameAsContentBlock()` - Verifies plain text handling

---

#### HTMLExporterTests.swift
**Location**: `WriterTests/HTMLExporterTests.swift`  
**Purpose**: Unit tests for HTMLExporter

(Note: File not explored in detail, but follows same pattern as other test files)

---

#### TableFormatterTests.swift
**Location**: `WriterTests/TableFormatterTests.swift`  
**Purpose**: Unit tests for TableFormatter

(Note: File not explored in detail, but follows same pattern as other test files)

---

#### PreviewThemeTests.swift
**Location**: `WriterTests/PreviewThemeTests.swift`  
**Purpose**: Unit tests for PreviewTheme

(Note: File not explored in detail, but follows same pattern as other test files)
