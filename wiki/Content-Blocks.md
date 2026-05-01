# Content Blocks Specification

Writer supports the `iainc/Markdown-Content-Blocks` specification, allowing you to transclude external files directly in your markdown documents.

## Overview

Content blocks are standalone lines in your markdown or plain-text documents that reference external files. Writer processes these blocks during rendering to include their content inline.

### Key Benefits
- **Modular Writing**: Break large documents into smaller, manageable files
- **Reuse Content**: Reference the same file from multiple documents
- **Dynamic Data**: Include CSV/TSV tables that update when source changes
- **Code Inclusion**: Embed source code with syntax highlighting
- **Image Embedding**: Include images without uploading to separate hosting

---

## Syntax Specification

### Basic Syntax

A content block must occupy its own line, with up to 3 spaces of indentation:

```markdown
/path/to/file.md
```

### Syntax with Captions

Captions can be added using three styles:

#### Double Quotes
```markdown
/path/to/file.md "Caption in double quotes"
```

#### Single Quotes
```markdown
/path/to/file.md 'Caption in single quotes'
```

#### Parentheses
```markdown
/path/to/file.md (Caption in parentheses)
```

### Online Images

Online images (http/https) with supported extensions can be used:

```markdown
https://example.com/images/photo.jpg "My Photo"
https://example.com/diagrams/flow.png (System Flow Diagram)
```

### Escaping

To include literal quote characters in captions, use backslash escaping:

```markdown
/path/to/file.md "He said \"Hello\""
/path/to/file.md (Don't forget)
```

---

## Supported Block Types

### Transcluded Markdown
**File Extensions**: `.md`, `.markdown`, `.txt`

**Behavior**:
- File content is read and rendered through the markdown pipeline
- Supports nested content blocks (recursive transclusion)
- Inherits the parent document's rendering context

**Example**:
```markdown
# My Document

/chapter/introduction.md "Introduction"

Some more text here.
```

**Rendered Output**:
The content of `introduction.md` is rendered as if it were inline, including all markdown formatting, headings, lists, etc.

**Nested Content Blocks**:
If `introduction.md` itself contains a content block, that will also be processed (with recursion detection).

---

### Tables (CSV/TSV)
**File Extensions**: `.csv` (comma-separated), `.tsv` (tab-separated)

**Behavior**:
- File is parsed as delimited data
- First row becomes table header
- Subsequent rows become table body
- Generates HTML `<table>` markup

**Example CSV** (`budget.csv`):
```csv
Category,Amount,Year
Rent,1200,2026
Utilities,180,2026
Groceries,400,2026
```

**Markdown**:
```markdown
/data/budget.csv "Annual Budget"
```

**Rendered Output**:
```html
<table>
<thead><tr><th>Category</th><th>Amount</th><th>Year</th></tr></thead>
<tbody>
<tr><td>Rent</td><td>1200</td><td>2026</td></tr>
<tr><td>Utilities</td><td>180</td><td>2026</td></tr>
<tr><td>Groceries</td><td>400</td><td>2026</td></tr>
</tbody>
</table>
<figcaption class="content-block-caption">Annual Budget</figcaption>
```

---

### Code Blocks
**File Extensions**: Many common programming languages

**Supported Extensions**:
`.c`, `.cc`, `.cpp`, `.css`, `.go`, `.h`, `.hpp`, `.html`, `.java`, `.js`, `.json`, `.kt`, `.m`, `.mm`, `.php`, `.py`, `.rb`, `.rs`, `.sh`, `.sql`, `.swift`, `.ts`, `.tsx`, `.xml`, `.yaml`, `.yml`, `.zsh`

**Behavior**:
- File content is wrapped in `<pre><code>` tags
- Language class added for potential syntax highlighting
- No actual syntax highlighting (just markup)

**Example** (`helpers.swift`):
```swift
func greet(name: String) {
    print("Hello, \(name)!")
}
```

**Markdown**:
```markdown
/src/helpers.swift "Helper Functions"
```

**Rendered Output**:
```html
<pre><code class="language-swift">func greet(name: String) {
    print("Hello, \(name)!")
}
</code></pre>
<figcaption class="content-block-caption">Helper Functions</figcaption>
```

---

### Images
**File Extensions**: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`, `.heic`, `.heif`, `.tif`, `.tiff`

**Behavior**:
- Image is read from disk or URL
- Converted to base64-encoded data URI
- Embedded directly in HTML (self-contained)
- Supports both local files and online URLs

**Local Image Example**:
```markdown
/images/screenshot.png "App Screenshot"
```

**Online Image Example**:
```markdown
https://example.com/photos/team.jpg (Our Team)
```

**Rendered Output** (local):
```html
<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..." alt="App Screenshot">
<figcaption class="content-block-caption">App Screenshot</figcaption>
```

**Rendered Output** (online):
```html
<img src="https://example.com/photos/team.jpg" alt="Our Team">
<figcaption class="content-block-caption">Our Team</figcaption>
```

---

## Path Resolution

### Local File Paths

Local paths are resolved in the following order:

1. **Absolute Paths** (starting with `/`):
   ```markdown
   /Users/emmett/Documents/chapter1.md
   ```

2. **Relative to Current Document**:
   If editing `/Users/emmett/Documents/book/draft.md`:
   ```markdown
   chapters/intro.md  # Resolves to /Users/emmett/Documents/book/chapters/intro.md
   ```

3. **Relative to Workspace Root**:
   If workspace root is `/Users/emmett/Documents/`:
   ```markdown
   assets/logo.png  # Resolves to /Users/emmett/Documents/assets/logo.png
   ```

### Online URLs

URLs starting with `http://` or `https://` are treated as online content:
- Only image URLs with supported extensions are processed
- Other URLs are not treated as content blocks

---

## Error Handling

When a content block cannot be properly rendered, Writer displays a warning block instead of failing silently.

### Warning Block Types

#### Missing Content Block
**Trigger**: File not found at resolved path

**Example**:
```markdown
/missing/file.md
```

**Output**:
```html
<div class="content-block content-block-warning">
    <p><strong>Missing content block:</strong> /missing/file.md</p>
    <pre><code>/missing/file.md</code></pre>
</div>
```

#### Recursive Content Block
**Trigger**: Content block references a file that (directly or indirectly) includes itself

**Example**:
`a.md` contains:
```markdown
b.md
```
`b.md` contains:
```markdown
a.md
```

**Output**:
```html
<div class="content-block content-block-warning">
    <p><strong>Recursive content block:</strong> a.md</p>
    <pre><code>a.md</code></pre>
</div>
```

#### Unreadable Content Block
**Trigger**: File exists but cannot be read (permissions, corruption)

**Output**:
```html
<div class="content-block content-block-warning">
    <p><strong>Unreadable content block:</strong> file.md</p>
    <pre><code>/path/to/file.md</code></pre>
</div>
```

#### Empty Table Block
**Trigger**: CSV/TSV file has no data rows or only a header

**Output**:
```html
<div class="content-block content-block-warning">
    <p><strong>Empty table block:</strong> data.csv</p>
    <pre><code>/path/to/data.csv</code></pre>
</div>
```

#### Unsupported Content Block
**Trigger**: File extension is not in the supported list

**Output**:
```html
<div class="content-block content-block-warning">
    <p><strong>Unsupported content block:</strong> presentation.pptx</p>
    <pre><code>/path/to/presentation.pptx</code></pre>
</div>
```

---

## Visual Indication in Editor

In the MarkdownTextView editor, content blocks are visually marked:

- **Valid Block** (file exists): Light blue background with blue text
- **Invalid Block** (file missing): Light orange background with orange text

This helps you identify broken references at a glance.

---

## Best Practices

### Organize Your Files

```
workspace/
├── main.md              # Main document
├── chapters/            # Chapter files
│   ├── intro.md
│   ├── chapter1.md
│   └── conclusion.md
├── data/                # CSV/TSV data files
│   ├── budget.csv
│   └── metrics.tsv
├── images/              # Image files
│   ├── screenshot.png
│   └── diagram.jpg
└── src/                 # Source code files
    └── helpers.swift
```

### Use Captions

Always include captions for clarity:
```markdown
/chapters/intro.md "Introduction Chapter"
/data/sales.csv "Q1 Sales Data"
```

### Avoid Deep Nesting

While nested content blocks are supported, avoid deep recursion:
- **Good**: 1-2 levels of nesting
- **Risky**: 3+ levels (harder to debug, slower rendering)

### Prefer Relative Paths

Relative paths make your workspace portable:
```markdown
# Good - relative to workspace
/data/stats.csv

# Less portable - absolute path
/Users/emmett/Documents/Project/data/stats.csv
```

### Check for Broken Links

Use the visual indication in the editor:
- Orange background = fix the path
- Ensure referenced files are within your workspace or use absolute paths

---

## Examples

### Complete Document Example

`main.md`:
```markdown
# My Book

## Introduction

/chapters/intro.md "Introduction"

## Chapter 1

/chapters/chapter1.md

Here's the budget data:

/data/budget.csv (Annual Budget)

## Appendix

### Source Code

/src/helpers.swift "Helper Functions"

### Architecture Diagram

/images/architecture.png "System Architecture"
```

### Nested Content Blocks Example

`main.md`:
```markdown
# Documentation

/sections/setup.md "Setup Guide"
```

`setup.md`:
```markdown
## Setup Instructions

Follow these steps:

1. Install dependencies
2. Configure settings
3. Run initialization

For detailed config, see:

/config/details.md "Configuration Details"
```

`details.md`:
```markdown
## Advanced Configuration

Here are the advanced options...
```

**Rendering**: All three files are rendered inline in the correct order.

---

## Technical Details

### ContentBlockSyntax Structure

```swift
struct ContentBlockSyntax {
    struct ContentBlockMatch {
        let path: String              // File path or URL
        let caption: String?          // Optional caption
        let captionStyle: CaptionStyle? // doubleQuoted, singleQuoted, parenthesized
        let originalLine: String      // Original line from document
    }
    
    struct ResolvedContentBlock {
        let match: ContentBlockMatch
        let url: URL?                  // Resolved URL (nil if not found)
    }
    
    enum CaptionStyle {
        case doubleQuoted
        case singleQuoted
        case parenthesized
    }
    
    static func parseLine(_ line: String) -> ContentBlockMatch?
    static func resolve(_ match: ContentBlockMatch, context: MarkdownRenderContext) -> ResolvedContentBlock
}
```

### Parsing Process

1. **parseLine()**: Detects if a line is a content block
   - Checks indentation (≤3 spaces)
   - Extracts path
   - Extracts caption (if any)
   - Determines caption style

2. **resolve()**: Converts parsed match to resolved block
   - Normalizes path (expands `~`)
   - Checks if online URL
   - Searches for local file (absolute → relative to doc → relative to workspace)
   - Returns URL if found, nil if missing

3. **classifyContentBlock()**: Determines block type from file extension
   - Returns `.transcludedMarkdown`, `.code()`, `.table()`, `.image()`, or `.unsupported`

4. **render*Block()**: Generates appropriate HTML for each block type

### Recursion Detection

Writer tracks visited URLs to prevent infinite loops:
```swift
static func renderBodyContent(_ markdown: String, context: MarkdownRenderContext, visitedURLs: Set<URL>) {
    // ...
    if visitedURLs.contains(url) {
        return renderWarningBlock(title: "Recursive content block", ...)
    }
    // Recursively render with updated visitedURLs
    let nestedHTML = renderBodyContent(contents, context: nestedContext, visitedURLs: visitedURLs.union([url]))
}
```

---

## Limitations

### File Size

Very large files (especially images) may impact performance:
- Images are base64-encoded (increases size by ~33%)
- Large CSV files may slow rendering

### Online Images

- Only images with supported extensions are embedded
- No authentication support for private URLs
- Network failures will show warning block

### Nested Content Blocks

- Maximum recursion depth is not explicitly limited (relies on visitedURLs set)
- Extremely deep nesting may cause performance issues

### Markdown Extensions

- Only standard Markdown syntax is supported (via Apple's Markdown framework)
- No support for custom markdown extensions inside transcluded files

---

## Summary

Content blocks are a powerful feature for modular document authoring:

| Feature | Syntax | Output |
|---------|---------|--------|
| Transcluded Markdown | `/path/file.md "Caption"` | Rendered markdown content |
| CSV Table | `/data/file.csv (Caption)` | HTML `<table>` |
| TSV Table | `/data/file.tsv` | HTML `<table>` |
| Code Block | `/src/file.swift` | `<pre><code>` |
| Image (local) | `/images/photo.png` | Base64-embedded `<img>` |
| Image (online) | `https://.../photo.jpg` | Direct `<img>` |
| Warning (error) | `/missing/file.md` | Warning `<div>` |

Use content blocks to create modular, maintainable documents with reusable components.
