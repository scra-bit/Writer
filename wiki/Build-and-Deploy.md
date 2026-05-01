# Build and Deploy Guide

This guide covers building Writer from source, running tests, and setting up CI/CD.

## Prerequisites

### System Requirements
- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Command Line Tools**: Required for building from terminal

### Verify Installation

Check Xcode version:
```bash
xcodebuild -version
```

Check Swift version:
```bash
swift --version
```

Install Command Line Tools (if needed):
```bash
xcode-select --install
```

---

## Building from Source

### Using Xcode (Recommended)

1. **Open the Project**:
   ```bash
   cd /path/to/Writer
   open Writer.xcodeproj
   ```

2. **Select Scheme**:
   - In Xcode toolbar, ensure "Writer" scheme is selected
   - Destination: "My Mac" (or your Mac's name)

3. **Build**:
   - Menu: Product → Build (⌘B)
   - Or: Click the "Play" button in toolbar

4. **Run**:
   - Menu: Product → Run (⌘R)
   - App will launch with a debug console

5. **Clean Build** (if needed):
   - Menu: Product → Clean Build Folder (⇧⌘K)
   - Then build again

### Using Terminal (xcodebuild)

Build from command line:
```bash
xcodebuild -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS' build
```

Run tests:
```bash
xcodebuild -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS' test
```

---

## Project Structure

```
Writer/
├── Writer.xcodeproj/              # Xcode project file
├── Writer/                         # Main application code
│   ├── WriterApp.swift
│   ├── ContentView.swift
│   ├── EditorStore.swift
│   └── ... (other Swift files)
├── WriterTests/                     # Unit tests
│   ├── EditorStoreTests.swift
│   ├── MarkdownRendererTests.swift
│   └── ... (other test files)
├── .github/
│   └── workflows/
│       └── objective-c-xcode.yml   # CI/CD workflow
├── CLAUDE.md                       # AI assistant instructions
├── README.md                       # Project readme
└── LICENSE.md                      # MIT License
```

---

## Dependencies

Writer uses **Swift Package Manager (SPM)** implicitly through Xcode's native support.

### Frameworks Used

| Framework/Library | Purpose |
|-------------------|---------|
| `SwiftUI` | Modern declarative UI framework |
| `Observation` | Reactive state management (@Observable) |
| `Markdown` | Apple's native markdown parsing framework |
| `WebKit` | WKWebView for preview rendering |
| `AppKit` | Cocoa framework (NSViewRepresentable, NSTextView, etc.) |
| `UniformTypeIdentifiers` | UTType for file type identification |
| `Foundation` | Core Foundation types and utilities |

### No External Dependencies

Writer is intentionally dependency-light:
- Uses Apple's native frameworks only
- No CocoaPods, Carthage, or SPM packages required
- Ensures long-term maintainability and security

---

## Code Signing and Entitlements

### Development Signing

For local development, Xcode automatically signs with your development certificate.

**Settings**:
1. Select "Writer" project in Navigator
2. Select "Writer" target
3. Go to "Signing & Capabilities" tab
4. Set "Team" to your Apple ID
5. Bundle Identifier: `EmmettBuckThompson.Writer`

### Entitlements

Writer uses security-scoped bookmarks which require specific entitlements.

**App Sandbox** (if enabled):
- May need to disable for bookmark functionality
- Or add specific file access entitlements

**Security-Scoped Bookmarks**:
- Not a standard entitlement
- Uses `URL.bookmarkData(options: .withSecurityScope)`
- Stored in UserDefaults, not Keychain

### Distribution Signing

For distributing outside the App Store:

1. **Create Distribution Certificate**:
   - Apple Developer Portal → Certificates → Create Certificate
   - Choose "Developer ID Application"

2. **Update Build Settings**:
   - Target → Build Settings → Code Signing Identity
   - Set to "Developer ID Application"

3. **Archive and Export**:
   - Product → Archive
   - In Organizer, click "Distribute App"
   - Choose "Developer ID" → Export

---

## GitHub Actions CI/CD

Writer includes a GitHub Actions workflow for automated building, testing, and analysis.

### Workflow File

Location: `.github/workflows/objective-c-xcode.yml`

**Triggers**:
- Push to `main` branch
- Pull requests to `main` branch

**Runner**: `macos-latest`

### Workflow Steps

```yaml
name: Xcode - Build, Test, and Analyze

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  build:
    name: Build, test, and analyse default scheme using xcodebuild command
    runs-on: macos-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Set Default Scheme
        run: |
          scheme_list=$(xcodebuild -list -json | tr -d "\n")
          default=$(echo $scheme_list | ruby -e "require 'json'; puts JSON.parse(STDIN.gets)['project']['targets'][0]")
          echo $default | cat >default
          echo Using default scheme: $default
          
      - name: Build And Test
        env:
          scheme: ${{ 'default' }}
        run: |
          if [ $scheme = default ]; then scheme=$(cat default); fi
          if [ "`ls -A | grep -i \\.xcworkspace\$`" ]; then filetype_parameter="workspace" && file_to_build="`ls -A | grep -i \\.xcworkspace\$`"; else filetype_parameter="project" && file_to_build="`ls -A | grep -i \\.xcodeproj\$`"; fi
          file_to_build=`echo $file_to_build | awk '{$1=$1;print}'`
          xcodebuild clean build test analyze -scheme "$scheme" -destination 'platform=macOS' -"$filetype_parameter" "$file_to_build" | xcpretty && exit ${PIPESTATUS[0]}
```

### What the Workflow Does

1. **Checkout**: Pulls the latest code from the repository
2. **Set Default Scheme**: Detects the default Xcode scheme automatically
3. **Build and Test**:
   - `clean` - Cleans previous build artifacts
   - `build` - Compiles the project
   - `test` - Runs all unit tests
   - `analyze` - Performs static code analysis
   - Pipes through `xcpretty` for readable output

### Local Testing Before Push

Run the same checks locally before pushing:

```bash
# Clean build
xcodebuild clean -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'

# Build
xcodebuild build -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'

# Test
xcodebuild test -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'

# Analyze
xcodebuild analyze -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'
```

---

## Running Tests

### In Xcode

1. **Run All Tests**:
   - Menu: Product → Test (⌘U)
   - Or: Click diamond icons in gutter next to test methods

2. **Run Specific Test Class**:
   - In Test Navigator (⌘6), click play button next to test class

3. **Run Single Test**:
   - Click diamond icon next to specific test method

### Using xcodebuild

Run all tests:
```bash
xcodebuild test -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS'
```

Run specific test class:
```bash
xcodebuild test -project Writer.xcodeproj -scheme Writer -destination 'platform=macOS' -only-testing:WriterTests/EditorStoreTests
```

### Test Coverage

Current test files:
- `EditorStoreTests.swift` - File operations, document persistence
- `MarkdownRendererTests.swift` - HTML rendering, content blocks
- `HTMLExporterTests.swift` - HTML export functionality
- `TableFormatterTests.swift` - Table detection and formatting
- `PreviewThemeTests.swift` - Theme CSS generation

---

## Build Configurations

### Debug
- Optimizations: None
- Includes debug symbols
- Assertions enabled
- Fast build times

### Release
- Optimizations: Full (-O)
- Strips debug symbols
- Dead code stripping enabled
- Optimized for distribution

### Switching Configurations

In Xcode:
1. Product → Scheme → Edit Scheme (⌘<)
2. Select "Run" → "Info" tab
3. Change "Build Configuration" to Debug or Release

---

## Common Build Issues

### "No such module 'Markdown'"

**Cause**: Apple's Markdown framework not found.

**Solution**:
- Ensure you're building with Xcode 15.0+
- The Markdown framework is included with Xcode 15+
- Try: File → Packages → Reset Package Caches

### "Signing for 'Writer' requires a development team"

**Solution**:
1. Open project settings
2. Select "Writer" target
3. "Signing & Capabilities" tab
4. Select your team from dropdown

### "Building for macOS, but the embedded framework 'X' was built for iOS"

**Cause**: Framework built for wrong platform.

**Solution**:
- Writer is macOS-only
- Ensure all frameworks are for macOS
- Check target settings: "Supported Platforms" = macOS

### Test Failures

**Issue**: Tests fail with file permission errors.

**Solution**:
- Tests create temporary directories in `FileManager.default.temporaryDirectory`
- Ensure your user has write access to `/tmp`
- Try running tests in Xcode (which handles sandboxing differently)

---

## Release Process

### Versioning

Writer uses semantic versioning (not currently automated):

1. Update version in Xcode:
   - Target → General → Identity → Version
   - Target → General → Identity → Build

2. Tag the release:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

### Creating Release Build

1. **Clean**:
   ```bash
   xcodebuild clean -project Writer.xcodeproj -scheme Writer -configuration Release
   ```

2. **Archive**:
   - In Xcode: Product → Archive
   - Wait for Organizer to appear

3. **Export**:
   - Click "Distribute App"
   - Choose method (Developer ID for outside App Store)
   - Follow prompts to export .app or .dmg

### Automated Builds

The GitHub Actions workflow automatically:
- Builds on every push to `main`
- Runs tests on every pull request
- Provides build status via commits and PR checks

---

## Contributing

### Before You Start

1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
4. **Build** the project to ensure it works

### Making Changes

1. **Code**: Make your changes in Xcode
2. **Test**: Run existing tests and add new ones
3. **Build**: Ensure project builds without warnings
4. **Format**: Follow existing code style

### Submitting

1. **Commit**: Use conventional commit messages (see CLAUDE.md)
   ```bash
   git commit -m "feat: add amazing feature"
   ```

2. **Push**: Push to your fork
   ```bash
   git push origin feature/amazing-feature
   ```

3. **PR**: Open a Pull Request on GitHub
   - CI will automatically build and test
   - Address any failing checks

### Code Review

- All PRs require review
- CI must pass (build + tests)
- Follow existing code style
- Update documentation if needed
