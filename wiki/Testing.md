# Testing Guide

Writer uses XCTest for unit testing, with a focus on testing core business logic and rendering functionality.

## Test Structure

### Directory Layout

```
Writer/
├── Writer/                    # Application code
│   ├── EditorStore.swift
│   ├── MarkdownRenderer.swift
│   └── ... (other source files)
└── WriterTests/               # Test files
    ├── EditorStoreTests.swift
    ├── MarkdownRendererTests.swift
    ├── HTMLExporterTests.swift
    ├── TableFormatterTests.swift
    ├── PreviewThemeTests.swift
    └── ... (other test files)
```

### Test Files

| Test File | Tests | Coverage Area |
|-----------|-------|----------------|
| `EditorStoreTests.swift` | 3 | File operations, document persistence, file management |
| `MarkdownRendererTests.swift` | 6 | HTML rendering, content blocks, escaping |
| `HTMLExporterTests.swift` | - | HTML export functionality |
| `TableFormatterTests.swift` | - | Table detection, formatting, alignment |
| `PreviewThemeTests.swift` | - | Theme CSS generation, color values |

---

## Running Tests

### In Xcode

#### Run All Tests
1. Menu: **Product → Test** (⌘U)
2. Or: Click the diamond icon in Test Navigator (⌘6)

#### Run Specific Test Class
1. Open Test Navigator (⌘6)
2. Click the play button next to the test class

#### Run Single Test
1. Click the diamond icon in the gutter next to the test method
2. Or: Click diamond in Test Navigator

#### View Test Results
1. Open Test Navigator (⌘6)
2. Expand test classes to see individual results
3. Click failed tests to see error details

### Using xcodebuild

#### Run All Tests
```bash
xcodebuild test \
  -project Writer.xcodeproj \
  -scheme Writer \
  -destination 'platform=macOS'
```

#### Run Specific Test Class
```bash
xcodebuild test \
  -project Writer.xcodeproj \
  -scheme Writer \
  -destination 'platform=macOS' \
  -only-testing:WriterTests/EditorStoreTests
```

#### Run Single Test Method
```bash
xcodebuild test \
  -project Writer.xcodeproj \
  -scheme Writer \
  -destination 'platform=macOS' \
  -only-testing:WriterTests/EditorStoreTests/testRefreshFilesFiltersFilesAndSelectsFirstEditableFile
```

### Using swift test (if Swift Package)

Writer is an Xcode project, not a Swift package, so `swift test` is not applicable.

---

## Writing New Tests

### Test File Structure

```swift
import XCTest
@testable import Writer  // Required to access internal members

@MainActor
final class MyNewTests: XCTestCase {
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Setup code here
    }
    
    override func tearDownWithError() throws {
        // Cleanup code here
        try super.tearDownWithError()
    }
    
    // MARK: - Tests
    
    func testFeatureDoesSomething() throws {
        // Arrange
        let store = EditorStore()
        
        // Act
        store.doSomething()
        
        // Assert
        XCTAssertEqual(store.state, expectedState)
    }
}
```

### Key Patterns

#### 1. Use @MainActor for Store Tests

Since `EditorStore`, `ThemeStore`, etc. are marked `@MainActor`:

```swift
@MainActor
final class EditorStoreTests: XCTestCase {
    // Tests here
}
```

#### 2. Create Temporary Workspaces

For file-related tests, create isolated temporary directories:

```swift
func testFileOperation() throws {
    // Arrange
    let rootURL = try makeTemporaryWorkspace()
    let fileURL = rootURL.appendingPathComponent("test.txt")
    try "content".write(to: fileURL, atomically: true, encoding: .utf8)
    
    // Act & Assert
    let store = EditorStore(rootURL: rootURL, restoreSavedFolder: false)
    XCTAssertEqual(store.fileTree.count, 1)
    
    // Cleanup is handled by addTeardownBlock in helper
}

private func makeTemporaryWorkspace() throws -> URL {
    let rootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
    
    addTeardownBlock {
        try? FileManager.default.removeItem(at: rootURL)
    }
    
    return rootURL
}
```

#### 3. Test Async Code

For async methods (like exporters):

```swift
func testExportGeneratesValidHTML() async throws {
    let exporter = HTMLExporter(
        markdown: "# Hello",
        theme: .sansSerif
    )
    
    let url = try await exporter.save(suggestedName: "test.html")
    
    let content = try String(contentsOf: url, encoding: .utf8)
    XCTAssertTrue(content.contains("<h1>Hello</h1>"))
    
    // Cleanup
    try? FileManager.default.removeItem(at: url)
}
```

#### 4. Use @testable import

To access internal types and methods:

```swift
@testable import Writer  // Instead of just `import Writer`
```

This allows testing of `internal` and `public` (but not `private`) members.

---

## Test Coverage Areas

### EditorStore Tests

**Covered**:
- ✅ File tree loading and filtering
- ✅ Document persistence
- ✅ File operations (create, rename, move, copy, paste, delete)
- ✅ Clipboard operations
- ✅ Auto-save scheduling

**Example Test**:
```swift
func testRefreshFilesFiltersFilesAndSelectsFirstEditableFile() throws {
    let rootURL = try makeTemporaryWorkspace()
    let draftsURL = rootURL.appendingPathComponent("Drafts", isDirectory: true)
    try FileManager.default.createDirectory(at: draftsURL, withIntermediateDirectories: true)
    try "draft".write(to: draftsURL.appendingPathComponent("chapter.md"), atomically: true, encoding: .utf8)
    try "alpha".write(to: rootURL.appendingPathComponent("alpha.txt"), atomically: true, encoding: .utf8)
    try "skip".write(to: rootURL.appendingPathComponent("image.png"), atomically: true, encoding: .utf8)
    try "hidden".write(to: rootURL.appendingPathComponent(".hidden.md"), atomically: true, encoding: .utf8)
    
    let store = EditorStore(rootURL: rootURL, restoreSavedFolder: false)
    
    XCTAssertEqual(store.fileTree.map(\.name), ["Drafts", "alpha.txt"])
    XCTAssertEqual(store.fileTree.first?.children?.map(\.name), ["chapter.md"])
    XCTAssertEqual(store.selectedFileURL?.lastPathComponent, "chapter.md")
    XCTAssertEqual(store.documentText, "draft")
}
```

### MarkdownRenderer Tests

**Covered**:
- ✅ HTML escaping and markdown rendering
- ✅ Highlight syntax processing (`==text==`)
- ✅ HTML document wrapping with theme CSS
- ✅ Content block transclusion
- ✅ Warning blocks for missing content
- ✅ CSV content blocks rendered as tables
- ✅ Plain filenames not treated as content blocks

**Example Test**:
```swift
func testRenderBodyContentEscapesHTMLAndRendersMarkdown() {
    let markdown = """
    # Title
    
    Paragraph with **bold** and <script>.
    """
    
    let html = MarkdownRenderer.renderBodyContent(markdown)
    
    XCTAssertTrue(html.contains("<h1>Title</h1>"), html)
    XCTAssertTrue(html.contains("<strong>bold</strong>"), html)
    XCTAssertFalse(html.contains("<script>"), html)
    XCTAssertTrue(html.contains("&lt;script"), html)
}
```

### HTMLExporter Tests

**Should Cover**:
- [ ] HTML generation with theme CSS
- [ ] Save panel presentation
- [ ] File writing to disk
- [ ] Error handling (cancelled, write failed)

### TableFormatter Tests

**Should Cover**:
- [ ] Table detection in text
- [ ] Delimiter row parsing
- [ ] Column alignment detection
- [ ] Column width calculation (including CJK)
- [ ] Table formatting with proper padding
- [ ] Entire document formatting

### PreviewTheme Tests

**Should Cover**:
- [ ] CSS generation for each theme
- [ ] Color values correctness
- [ ] Font family strings
- [ ] Print media query inclusion
- [ ] All themes in `allThemes` array

---

## Best Practices

### 1. Test One Thing Per Test

```swift
// Good
func testCreateFileCreatesFileOnDisk() { ... }
func testCreateFileUpdatesFileTree() { ... }

// Avoid
func testCreateFile() {
    // Tests creation, updating, selection, etc. all in one
}
```

### 2. Use Descriptive Test Names

```swift
// Good
func testRefreshFilesFiltersFilesAndSelectsFirstEditableFile() { ... }
func testPersistCurrentDocumentWritesChangesToDisk() { ... }

// Avoid
func test1() { ... }
func testRefresh() { ... }
```

### 3. Follow Arrange-Act-Assert

```swift
func testExample() throws {
    // Arrange: Set up test conditions
    let store = EditorStore()
    
    // Act: Perform the action being tested
    store.doSomething()
    
    // Assert: Verify the result
    XCTAssertEqual(store.state, expectedState)
}
```

### 4. Clean Up Resources

```swift
func testWithTemporaryFile() throws {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("test.txt")
    try "content".write(to: tempURL, atomically: true, encoding: .utf8)
    
    // Test...
    
    // Cleanup
    try? FileManager.default.removeItem(at: tempURL)
}
```

Or use `addTeardownBlock` for automatic cleanup.

### 5. Use XCTAssert Variants

```swift
XCTAssertTrue(condition)              // Boolean condition
XCTAssertFalse(condition)             // Negated condition
XCTAssertEqual(value1, value2)        // Equality
XCTAssertNotEqual(value1, value2)     // Inequality
XCTAssertNil(value)                    // Nil check
XCTAssertNotNil(value)                 // Not nil check
XCTAssertThrowsError(try expression)    // Expects error
XCTAssertNoThrow(try expression)        // Expects no error
```

### 6. Test Error Conditions

```swift
func testMissingFileShowsWarning() {
    let html = MarkdownRenderer.renderBodyContent(
        "/missing/file.md",
        context: MarkdownRenderContext()
    )
    
    XCTAssertTrue(html.contains("Missing content block"))
    XCTAssertTrue(html.contains("/missing/file.md"))
}
```

---

## Continuous Integration

### GitHub Actions

Tests run automatically via GitHub Actions on:
- **Push** to `main` branch
- **Pull Request** to `main` branch

**Workflow Step**:
```yaml
- name: Build And Test
  run: |
    xcodebuild clean build test analyze \
      -scheme "$scheme" \
      -destination 'platform=macOS' \
      -project Writer.xcodeproj | xcpretty
```

### Viewing CI Results

1. Open your repository on GitHub
2. Click **Actions** tab
3. Select the workflow run
4. View build log and test results
5. Failed tests will be highlighted in red

### Running CI Checks Locally

Before pushing, run the same checks locally:

```bash
# Clean build
xcodebuild clean -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'

# Build
xcodebuild build -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'

# Test
xcodebuild test -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'

# Analyze (static analysis)
xcodebuild analyze -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'
```

---

## Debugging Tests

### Test Navigator

1. Open Test Navigator (⌘6)
2. Expand test classes to see individual tests
3. Click diamonds to run specific tests
4. View failure messages by clicking failed tests

### Breakpoints in Tests

1. Click gutter next to test method or code line
2. Run test (⌘U or click diamond)
3. Execution pauses at breakpoint
4. Use debugger to inspect variables

### Printing Debug Info

```swift
func testExample() throws {
    let html = MarkdownRenderer.renderBodyContent(markdown)
    
    print("Generated HTML:\n\(html)")  // Debug output
    
    XCTAssertTrue(html.contains("expected"))
}
```

View output in Xcode's Console (⇧⌘C).

### Common Test Failures

#### "No such file or directory"
**Cause**: Temporary file/directory not created or already cleaned up.

**Fix**: Ensure proper setup in `makeTemporaryWorkspace()`.

#### "Ambiguous use of 'method'"
**Cause**: Type inference issue in Swift.

**Fix**: Add explicit type annotations.

#### "XCTAssertEqual failed: ..."
**Cause**: Actual value doesn't match expected.

**Fix**: Print actual value to debug, check logic.

---

## Code Coverage

### Enabling Coverage in Xcode

1. Edit Scheme (⌘<)
2. Select "Test" → "Options"
3. Check "Gather coverage for" → "All targets"
4. Close scheme editor
5. Run tests (⌘U)
6. View coverage in Report Navigator (⌘8)

### Coverage Report

After running tests with coverage enabled:
1. Open Report Navigator (⌘8)
2. Select the test run
3. Click "Coverage" tab
4. Expand to see per-file coverage percentages
5. Click file name to see highlighted source code

### Improving Coverage

Focus on:
- **EditorStore**: File operations, state management
- **MarkdownRenderer**: All rendering paths, edge cases
- **Exporters**: HTML, PDF, RTF generation
- **TableFormatter**: Detection, parsing, formatting

---

## Summary

| Aspect | Details |
|--------|---------|
| **Framework** | XCTest |
| **Test Location** | `WriterTests/` directory |
| **Import Method** | `@testable import Writer` |
| **Main Actor** | Required for `@Observable` store tests |
| **CI Integration** | GitHub Actions (`.github/workflows/`) |
| **Test Command** | `xcodebuild test -scheme Writer -destination 'platform=macOS'` |
| **Coverage** | Enabled in Scheme settings |

Writer's test suite focuses on:
1. **Core business logic** (EditorStore operations)
2. **Rendering correctness** (MarkdownRenderer output)
3. **Export functionality** (HTML, PDF, RTF)
4. **Edge cases** (missing files, malformed input, recursion)
