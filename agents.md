# agents.md

This file provides guidance to AI agents (OpenCode, Cursor, GitHub Copilot, etc.) when working with code in this repository.

## Quick Start

**For shared coding standards, architecture patterns, and development guidelines, see [.rules](./.rules).**

All agents should follow the patterns and guidelines documented in `.rules` when implementing features or making changes to this codebase.

## Project Overview

Writer is a distraction-free text editor for macOS, built with SwiftUI. It provides a markdown editing experience with live preview and HTML export capabilities.

## Wiki Documentation

Comprehensive documentation is available in the [wiki](./wiki/):

| Page | Description |
|------|-------------|
| [Home](./wiki/Home.md) | Project overview and getting started |
| [Architecture](./wiki/Architecture.md) | System architecture and data flow |
| [Components](./wiki/Components.md) | Detailed component documentation |
| [Features](./wiki/Features.md) | Feature documentation |
| [Build and Deploy](./wiki/Build-and-Deploy.md) | Build instructions and CI/CD |
| [Keyboard Shortcuts](./wiki/Keyboard-Shortcuts.md) | Complete shortcut reference |
| [Content Blocks](./wiki/Content-Blocks.md) | Content block syntax specification |
| [Testing](./wiki/Testing.md) | Testing guide |

## Build & Run

- **Open in Xcode**: `open Writer.xcodeproj`
- **Build**: Product → Build (⌘B)
- **Run**: Product → Run (⌘R)
- **Test**: Product → Test (⌘U)

## Key Architecture Points

- **State Management**: Uses Swift's Observation framework (`@Observable`)
- **Dependencies**: Injected via SwiftUI environment (`EditorStore`, `ThemeStore`, `LayoutStore`, `CommandPaletteStore`)
- **Markdown Rendering**: Uses Apple's `Markdown` framework with custom `MarkupVisitor`
- **Security**: Uses security-scoped bookmarks for folder access persistence

## For Detailed Guidelines

See [.rules](./.rules) for:
- Code style guidelines
- Architecture patterns
- File organization standards
- Development best practices
- Build and test procedures

## Agent-Specific Notes

When working with this codebase:
1. Read `.rules` first for coding standards
2. Consult the [wiki](./wiki/) for detailed documentation
3. Follow the existing `@Observable` pattern for state management
4. Use SwiftUI environment for dependency injection
5. Maintain the custom `MarkupVisitor` pattern for Markdown rendering
6. Preserve security-scoped bookmark patterns for file access