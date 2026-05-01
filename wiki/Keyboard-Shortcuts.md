# Keyboard Shortcuts Reference

Complete reference for all keyboard shortcuts available in Writer.

## Quick Reference

| Shortcut | Action | Context |
|----------|--------|---------|
| ⌘N | New File | File menu, Command Palette |
| ⌘⇧N | New Folder | File menu, Command Palette |
| ⌘⇧E | Export to HTML | File menu, Command Palette |
| ⌘⇧R | Export to RTF | File menu, Command Palette |
| ⌘⇧D | Export to PDF | File menu, Command Palette |
| ⌘⇧F | Format Tables | File menu, Command Palette |
| ⌘⇧R | Refresh Folder | Command Palette only |
| ⌘S | Save | Command Palette only |
| ⌘/ | Show/Hide Preview | View menu, Toolbar, Command Palette |
| ⌘⇧P | Show Command Palette | Command Palette menu |
| ⌘Z | Undo | Edit menu |
| ⌘⇧Z | Redo | Edit menu |
| ⌘X | Cut | Edit menu |
| ⌘C | Copy | Edit menu |
| ⌘V | Paste | Edit menu |
| ⌘A | Select All | Edit menu |
| ↑/↓ | Navigate Command Palette | Command Palette open |
| Return | Execute Selected Command | Command Palette open |
| Escape | Hide Command Palette | Command Palette open |

---

## File Shortcuts

### New File
- **Shortcut**: ⌘N
- **Menu**: File → New File
- **Command Palette**: "New File"
- **Description**: Creates a new text file in the current directory
- **File Extension**: `.txt`
- **Behavior**: 
  - Opens a sheet to name the file
  - Creates empty file on disk
  - Automatically selects the new file for editing

### New Folder
- **Shortcut**: ⌘⇧N
- **Menu**: File → New Folder
- **Command Palette**: "New Folder"
- **Description**: Creates a new folder in the current directory
- **Behavior**:
  - Opens a sheet to name the folder
  - Creates directory on disk
  - Expands the new folder in sidebar
  - Sets as active directory

### Export to HTML
- **Shortcut**: ⌘⇧E
- **Menu**: File → Export to HTML
- **Command Palette**: "Export to HTML"
- **Description**: Exports current document as standalone HTML file
- **Output**: Complete HTML document with inline CSS
- **Enabled When**: Document is open or has content

### Export to RTF
- **Shortcut**: ⌘⇧R
- **Menu**: File → Export to RTF
- **Command Palette**: "Export to RTF"
- **Description**: Exports current document as Rich Text Format
- **Output**: .rtf file compatible with Word, Pages, etc.
- **Enabled When**: Document is open or has content

### Export to PDF
- **Shortcut**: ⌘⇧D
- **Menu**: File → Export to PDF
- **Command Palette**: "Export to PDF"
- **Description**: Exports current document as print-optimized PDF
- **Output**: Multi-page PDF with proper pagination
- **Enabled When**: Document is open or has content

### Format Tables
- **Shortcut**: ⌘⇧F
- **Menu**: File → Format Tables
- **Command Palette**: "Format Tables"
- **Description**: Auto-formats all markdown tables in the document
- **Actions**:
  - Detects markdown tables
  - Calculates optimal column widths
  - Aligns columns based on delimiter row
  - Preserves table content

### Refresh Folder
- **Shortcut**: None (Command Palette only)
- **Menu**: None (toolbar button available)
- **Command Palette**: "Refresh Folder"
- **Description**: Reloads file tree from disk
- **Use Case**: When files are added/removed outside the app

### Save
- **Shortcut**: ⌘S (Command Palette only)
- **Menu**: None (auto-save is default)
- **Command Palette**: "Save"
- **Description**: Manually saves current document
- **Note**: Writer auto-saves as you type (350ms debounce)

---

## Edit Shortcuts

### Undo
- **Shortcut**: ⌘Z
- **Menu**: Edit → Undo
- **Description**: Reverts the last text editing action
- **Scope**: Text editing within the editor

### Redo
- **Shortcut**: ⌘⇧Z
- **Menu**: Edit → Redo
- **Description**: Re-applies the last undone action
- **Scope**: Text editing within the editor

### Cut
- **Shortcut**: ⌘X
- **Menu**: Edit → Cut
- **Description**: Removes selected text and copies to clipboard
- **Scope**: Text editing within the editor

### Copy
- **Shortcut**: ⌘C
- **Menu**: Edit → Copy
- **Description**: Copies selected text to clipboard
- **Scope**: Text editing within the editor

### Paste
- **Shortcut**: ⌘V
- **Menu**: Edit → Paste
- **Description**: Inserts clipboard content at cursor position
- **Scope**: Text editing within the editor

### Select All
- **Shortcut**: ⌘A
- **Menu**: Edit → Select All
- **Description**: Selects all text in the current document
- **Scope**: Text editing within the editor

---

## View Shortcuts

### Show/Hide Preview
- **Shortcut**: ⌘/
- **Menu**: View → Show/Hide Preview
- **Toolbar**: Toggle button (arrow icon)
- **Command Palette**: "Show/Hide Preview"
- **Description**: Toggles the preview pane visibility
- **Behavior**:
  - When shown: Split view with editor and preview
  - When hidden: Editor fills entire detail area
  - Layout state persists via LayoutStore

---

## Command Palette Shortcuts

### Show Command Palette
- **Shortcut**: ⌘⇧P
- **Menu**: Command Palette → Show Command Palette
- **Description**: Opens the command palette overlay
- **Use Case**: Quick access to all commands without menus

### Navigate Commands
- **Shortcut**: ↑ (Up Arrow)
- **Context**: Command Palette open
- **Description**: Moves selection up in the command list

- **Shortcut**: ↓ (Down Arrow)
- **Context**: Command Palette open
- **Description**: Moves selection down in the command list

### Execute Command
- **Shortcut**: Return (↩)
- **Context**: Command Palette open
- **Description**: Executes the currently selected command
- **Behavior**: Closes palette after execution

### Dismiss Palette
- **Shortcut**: Escape (⎋)
- **Context**: Command Palette open
- **Description**: Closes the command palette without action

### Filter Commands
- **Action**: Type in search field
- **Context**: Command Palette open
- **Description**: Filters commands by name as you type
- **Clear**: Click X button or use keyboard shortcut (if any)

---

## Shortcut Conflicts

### ⌘⇧R Conflict
There are two commands using ⌘⇧R:
1. **Export to RTF** (File menu)
2. **Refresh Folder** (Command Palette only, no menu shortcut)

**Resolution**:
- In File menu, ⌘⇧R triggers RTF export
- In Command Palette, typing "refresh" and pressing Return triggers refresh
- No actual conflict since Refresh Folder has no global shortcut

### Common macOS Shortcuts (Not Overridden)

Writer respects standard macOS shortcuts and does not override:
- ⌘Q: Quit (system-handled)
- ⌘H: Hide (system-handled)
- ⌘M: Minimize (system-handled)
- ⌘W: Close Window (system-handled)
- ⌘Tab: Switch Apps (system-handled)

---

## Customizing Shortcuts

### macOS System Preferences

You can customize Writer shortcuts via macOS System Settings:

1. Open **System Settings**
2. Go to **Keyboard** → **Keyboard Shortcuts**
3. Click **App Shortcuts**
4. Click **+** to add new shortcut
5. Select "Writer" as the application
6. Enter exact menu item name (e.g., "New File")
7. Assign your preferred shortcut
8. Click **Done**

### Command Palette as Alternative

Since Writer doesn't expose all shortcuts via menus, the Command Palette (⌘⇧P) serves as a universal alternative:
- All commands are accessible regardless of menu shortcuts
- Search function helps find commands quickly
- Visual display shows available shortcuts

---

## Complete Shortcut Table

### By Category

#### File Operations
| Shortcut | Action |
|----------|--------|
| ⌘N | New File |
| ⌘⇧N | New Folder |
| ⌘⇧E | Export to HTML |
| ⌘⇧R | Export to RTF |
| ⌘⇧D | Export to PDF |
| ⌘⇧F | Format Tables |

#### Editing
| Shortcut | Action |
|----------|--------|
| ⌘Z | Undo |
| ⌘⇧Z | Redo |
| ⌘X | Cut |
| ⌘C | Copy |
| ⌘V | Paste |
| ⌘A | Select All |

#### View
| Shortcut | Action |
|----------|--------|
| ⌘/ | Show/Hide Preview |

#### Command Palette
| Shortcut | Action |
|----------|--------|
| ⌘⇧P | Show Command Palette |
| ↑ | Navigate Up |
| ↓ | Navigate Down |
| Return | Execute Command |
| Escape | Dismiss Palette |

### Alphabetical Reference

| Shortcut | Action | Menu Location |
|----------|--------|---------------|
| ⌘A | Select All | Edit |
| ⌘C | Copy | Edit |
| ⌘/ | Show/Hide Preview | View |
| ⌘N | New File | File |
| ⌘⇧N | New Folder | File |
| ⌘⇧P | Show Command Palette | Command Palette |
| ⌘⇧E | Export to HTML | File |
| ⌘⇧R | Export to RTF | File |
| ⌘⇧D | Export to PDF | File |
| ⌘⇧F | Format Tables | File |
| ⌘S | Save | (Command Palette only) |
| ⌘V | Paste | Edit |
| ⌘X | Cut | Edit |
| ⌘Z | Undo | Edit |
| ⌘⇧Z | Redo | Edit |
| ↑ | Navigate Up | (Command Palette) |
| ↓ | Navigate Down | (Command Palette) |
| Return | Execute Command | (Command Palette) |
| Escape | Dismiss Palette | (Command Palette) |

---

## Notes

### Why No ⌘S Shortcut in Menu?

Writer uses **auto-save** by default:
- Saves 350ms after you stop typing
- Manual save (⌘S) available via Command Palette
- Reduces cognitive load (no need to remember to save)

### Why ⌘/ for Preview?

- Quick toggle access
- Doesn't conflict with common text editing shortcuts
- Easy to reach (same key as ? but without Shift)

### Command Palette Philosophy

The Command Palette (⌘⇧P) is inspired by VS Code and provides:
- **Discoverability**: See all commands in one place
- **Efficiency**: Access any command without leaving keyboard
- **Search**: Find commands by name quickly
- **No Conflicts**: Doesn't require menu bar shortcut slots
