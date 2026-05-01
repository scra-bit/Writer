# Features Documentation

Writer provides a distraction-free writing experience with powerful markdown editing, live preview, and flexible export options.

## File Management

### Folder-Based Workspace

Writer operates on a folder-based workflow. On first launch, you select a "writing folder" that becomes your workspace.

**Features**:
- **Automatic File Discovery**: Automatically scans and displays all markdown and text files
- **Hierarchical View**: Subfolders are displayed in a tree structure
- **Hidden File Filtering**: Files starting with `.` are hidden from the sidebar
- **Supported File Types**: `.md`, `.markdown`, `.txt`, `.text`

### Security-Scoped Bookmarks

Writer uses macOS security-scoped bookmarks to remember your folder selection across app launches.

**How it works**:
1. First launch: Select folder via native NSOpenPanel
2. App creates a security-scoped bookmark
3. Bookmark saved to UserDefaults
4. Subsequent launches: Bookmark automatically resolved (no prompt)

**Benefits**:
- No need to re-select folder on every launch
- Maintains macOS sandbox security
- Folder access persists across app updates

### File Operations

#### Creating Files and Folders
- **New File** (⌘N): Creates a new text file in the current directory
- **New Folder** (⌘⇧N): Creates a new folder in the current directory
- Creation happens in the active directory (selected folder or parent of selected file)

#### File Organization
- **Rename**: Right-click → "Rename" or use context menu
- **Move**: Drag and drop files onto folders in the sidebar
- **Copy**: Right-click → "Copy", then navigate to destination → "Paste"
- **Cut**: Right-click → "Cut", then navigate to destination → "Paste"
- **Duplicate**: Right-click → "Duplicate" (creates "filename copy.ext")
- **Delete**: Right-click → "Move to Trash" (with confirmation)

#### Drag and Drop
- Drag files to reorder within the same directory
- Drag files onto folders to move them
- Handles duplicate names with replace/skip options

### File Tree Navigation

- **Expand/Collapse Folders**: Click disclosure triangle
- **Selection Highlighting**: Current selection highlighted in sidebar
- **Auto-Expand**: Folders expand automatically when containing selected file
- **Refresh**: Force refresh file tree (⌘⇧R or toolbar button)

---

## Markdown Editing

### Editor Features

Writer provides a custom NSTextView with real-time markdown syntax highlighting.

**Editor Characteristics**:
- Monospaced system font (SF Mono fallback)
- 16pt base font size (adjustable via theme settings)
- 24pt left indentation for visual structure
- Line spacing: 3pt
- Automatic quote/dash substitution disabled (preserves markdown syntax)

### Syntax Highlighting

Real-time syntax highlighting is applied as you type:

| Syntax | Markdown | Styling |
|--------|-----------|----------|
| Headings | `# H1`, `## H2`, etc. | Bold font + special indentation |
| Bold | `**text**` or `__text__` | Bold font |
| Italic | `*text*` or `_text_` | Italic font |
| Bold + Italic | `***text***` or `___text___` | Bold + Italic font |
| Strikethrough | `~~text~~` | Strikethrough + secondary color |
| Highlight | `==text==` | Yellow background highlight |
| Inline Code | `` `code` `` | Monospaced font + background |
| Content Blocks | `/path/file.md` | Blue (valid) or orange (missing) background |

**Note**: Highlighting is applied via regex pattern matching and respects order of operations (bold-italic takes precedence over bold/italic).

### Auto-Save

Writer automatically saves your work as you type:
- **Debounced Saving**: 350ms delay after last keystroke
- **Manual Save**: ⌘S (via Command Palette) or toolbar button
- **Dirty Tracking**: Only saves when content actually changed
- **UTF-8 Encoding**: All files saved as UTF-8

---

## Live Preview

### Real-Time Rendering

The preview pane shows your markdown rendered as HTML in real-time.

**Features**:
- **Instant Updates**: Preview updates as you type (no delay)
- **WKWebView**: Uses Apple's WebKit for accurate rendering
- **Theme Support**: Preview matches selected theme (Sans Serif or Serif)
- **Toggle Visibility**: Show/hide preview with ⌘/ or toolbar button

### Preview Themes

Writer includes two professionally designed preview themes:

#### Sans Serif (Default)
- **Body Font**: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
- **Heading Font**: system-ui, -apple-system, sans-serif
- **Code Font**: SF Mono, Menlo, Monaco, Courier New, monospace
- **Base Size**: 16px
- **Line Height**: 1.6

#### Serif
- **Body Font**: Georgia, "Times New Roman", Times, serif
- **Heading Font**: Georgia, "Times New Roman", serif
- **Code Font**: SF Mono, Menlo, Monaco, Courier New, monospace
- **Base Size**: 16px
- **Line Height**: 1.6

### Theme Selection

Switch themes via:
1. **Preview Overlay**: Click the paintbrush icon in the preview pane's bottom-right corner
2. **Theme Menu**: Dropdown shows all available themes

### Print-Optimized CSS

The preview HTML includes `@media print` styles for clean PDF export:
- Proper page breaks (no stranded headings)
- Orphans/widows control for paragraphs
- Unsplittable elements (tables, code blocks, images)
- Light theme forced for print (black text on white)

---

## Export Capabilities

Writer supports three export formats, each optimized for different use cases.

### HTML Export (⌘⇧E)

Exports your document as a standalone HTML file with inline CSS.

**Features**:
- **Self-Contained**: All CSS inlined in the HTML file
- **Theme-Styled**: Uses current preview theme for styling
- **Cross-Platform**: Opens in any web browser
- **Content Blocks Rendered**: Transcluded content included in output

**Use Cases**:
- Publish to web
- Share with non-Writer users
- Archive in web-friendly format

**Export Process**:
1. Trigger via menu, shortcut, or command palette
2. Save panel appears with suggested filename (`document.html`)
3. Choose destination and save

---

### PDF Export (⌘⇧D)

Exports your document as a paginated PDF using WebKit's print pipeline.

**Features**:
- **Proper Pagination**: Multi-page output with correct page breaks
- **Print CSS Respected**: `@media print` styles applied
- **US Letter Size**: 612×792 points (8.5"×11") with 1-inch margins
- **Light Theme**: Always exports with light background (dark text on white)
- **Content Blocks Included**: All transcluded content rendered

**Technical Details**:
- Uses `NSPrintOperation` (same as ⌘P → "Save as PDF")
- Not `WKWebView.createPDF` (which produces single continuous page)
- Temporary file used during generation, cleaned up after

**Use Cases**:
- Print to physical paper
- Share as formal document
- Archive in print-ready format

---

### RTF Export (⌘⇧R)

Exports your document as Rich Text Format for compatibility with other editors.

**Features**:
- **Universal Compatibility**: Opens in Microsoft Word, Pages, Google Docs, etc.
- **Styled Text**: Basic formatting preserved (bold, italic, etc.)
- **Theme Colors**: Uses current theme colors in RTF

**Export Process**:
1. Convert markdown → HTML (using MarkdownRenderer)
2. Convert HTML → NSAttributedString
3. Convert NSAttributedString → RTF data
4. Save panel appears with suggested filename (`document.rtf`)

**Use Cases**:
- Import into word processors
- Collaborate with non-markdown users
- Preserve formatting in editable format

---

## Content Blocks

Content blocks allow you to transclude external files directly in your markdown documents. Writer supports the `iainc/Markdown-Content-Blocks` specification.

### Supported Syntax

Content blocks must occupy their own line (optionally indented up to 3 spaces):

```markdown
/path/to/file.md
/path/to/data.csv "Caption in quotes"
/path/to/script.py 'Caption in single quotes'
https://example.com/image.png (Caption in parentheses)
```

**Caption Styles**:
- Double quotes: `"Caption"`
- Single quotes: `'Caption'`
- Parentheses: `(Caption)`

### Supported Block Types

| File Type | Block Type | Rendering |
|-----------|------------|-----------|
| `.md`, `.markdown`, `.txt` | Transcluded Markdown | Rendered through markdown pipeline (supports nested content blocks) |
| `.csv` | Table (comma-delimited) | Rendered as HTML `<table>` |
| `.tsv` | Table (tab-delimited) | Rendered as HTML `<table>` |
| `.png`, `.jpg`, `.jpeg` | Image | Embedded as base64 data URI |
| `.gif`, `.webp`, `.svg` | Image | Embedded as base64 data URI |
| `.heic`, `.heif`, `.tif`, `.tiff` | Image | Embedded as base64 data URI |
| Code files (`.swift`, `.js`, `.py`, etc.) | Code Block | Wrapped in `<pre><code>` with language class |

### Path Resolution

Local file paths are resolved in this order:
1. Absolute paths (starting with `/`)
2. Relative to current document's directory
3. Relative to workspace root directory

Online images (http/https URLs with image extensions) are embedded directly.

### Error Handling

Missing, recursive, malformed, or unsupported content blocks render as warning blocks:
```html
<div class="content-block content-block-warning">
    <p><strong>Missing content block:</strong> /path/to/file.md</p>
    <pre><code>/path/to/file.md "Caption"</code></pre>
</div>
```

**Warning Types**:
- "Missing content block" - File not found
- "Recursive content block" - Circular reference detected
- "Unreadable content block" - File can't be read
- "Unsupported content block" - File type not supported
- "Empty table block" - CSV/TSV with no data

### Example Usage

```markdown
# My Document

Here's an intro paragraph.

/sections/introduction.md "Introduction Section"

Here's a data table:

/data/budget.csv (Annual Budget)

And an image:

/images/diagram.png "System Architecture"

Check the code:

/src/helpers.swift
```

---

## Table Formatting

Writer includes intelligent markdown table formatting.

### Auto-Format Tables (⌘⇧F)

Automatically formats all markdown tables in the current document:
- Detects table boundaries (header, delimiter, body rows)
- Calculates optimal column widths
- Detects alignment from delimiter row (`:---`, `---:`, `:---:`)
- Handles Unicode/CJK character widths correctly
- Preserves table content

### Alignment Detection

The delimiter row determines column alignment:

| Delimiter | Alignment |
|-----------|------------|
| `:---` | Left |
| `---:` | Right |
| `:---:` | Center |
| `---` | None (defaults to left) |

### Example

**Before formatting**:
```markdown
|Name|Age|Role|
|---|---|---|
|Alice|30|Developer|
|Bob|25|Designer|
```

**After formatting** (⌘⇧F):
```markdown
| Name  | Age | Role      |
| :---- | :-- | :-------- |
| Alice | 30  | Developer |
| Bob   | 25  | Designer  |
```

### Supported Delimiters

- Comma-Separated Values (`.csv`) - rendered as table via content blocks
- Tab-Separated Values (`.tsv`) - rendered as table via content blocks
- Markdown tables - formatted in-place

---

## Command Palette (⌘⇧P)

Quick access to all Writer commands without using menus or keyboard shortcuts.

### Features

- **Searchable**: Type to filter commands by name
- **Keyboard Navigation**: Use ↑/↓ arrows to select, Return to execute
- **Visual Shortcuts**: Displays keyboard shortcuts for each command
- **Animated**: Smooth show/hide animation

### Available Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| New File | ⌘N | Create a new file |
| New Folder | ⌘⇧N | Create a new folder |
| Export to HTML | ⌘⇧E | Export document as HTML |
| Export to PDF | ⌘⇧D | Export document as PDF |
| Export to RTF | ⌘⇧R | Export document as RTF |
| Format Tables | ⌘⇧F | Auto-format all tables |
| Refresh Folder | - | Reload file tree from disk |
| Save | ⌘S | Save current document |
| Show/Hide Preview | ⌘/ | Toggle preview pane visibility |

### Usage

1. Press ⌘⇧P to open the command palette
2. Type to filter (e.g., "export" shows all export commands)
3. Use ↑/↓ to navigate the list
4. Press Return to execute the selected command
5. Press Escape to dismiss without action

---

## Additional Features

### Toolbar

The main toolbar provides quick access to:
- **Preview Toggle**: Show/hide preview pane (also ⌘/)
- **Save**: Manually save the current document
- **Refresh**: Reload the file tree from disk

### Context Menus

Right-click on files or folders to access:
- **Files**: Open, Rename, Duplicate, Copy, Cut, Paste, Show in Finder, Move to Trash
- **Folders**: New File, New Folder, Rename, Copy, Cut, Paste, Show in Finder, Open in Finder, Move to Trash

### Finder Integration

- **Show in Finder**: Reveals selected file/folder in Finder
- **Open in Finder**: Opens folder in Finder window
- **Drag to Finder**: Files can be dragged out to Finder

### Error Handling

Writer provides clear error messages for:
- Failed file operations (create, rename, move, delete)
- Failed exports (cancelled, write errors)
- Missing folder (bookmark invalid or deleted)
- Unreadable files

Errors appear as:
- Alert dialogs for export errors
- Inline text in sidebar for file operation errors
