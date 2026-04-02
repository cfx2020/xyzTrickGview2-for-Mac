# xyzTrickGview2 for Mac

A native macOS implementation of the XYZ Monitor molecular structure converter, built with SwiftUI.

## Features

- **Clipboard-based workflow**: Copy XYZ coordinates → press hotkey → view in GaussianView (or other molecular viewers)
- **Reverse conversion**: Convert structures back to XYZ format for data pipelines
- **Menu bar integration**: Lightweight system tray app with quick access menu
- **Global hotkeys**: Customizable keyboard shortcuts for instant conversion
- **Zero-interference**: Temporary files auto-deleted after viewing
- **Configuration panel**: Easy setup UI for paths, hotkeys, and preferences

## Requirements

- macOS 12.0 or later
- Xcode 15+ (for building from source)
- A molecular viewer (GaussianView, MOPAC, etc.) - configurable

## Quick Start

### Build from source (command line):

```bash
chmod +x build.sh
./build.sh release
```

This produces a standalone executable in `dist/XYZMonitor`.

### Or build with Xcode:

```bash
open Package.swift
# Click "Build" in Xcode (⌘B)
```

### Create a DMG for distribution:

```bash
chmod +x create-dmg.sh
./create-dmg.sh dist/XYZMonitor XYZMonitor.dmg
```

## Usage

1. **Launch the app**: The icon appears in the menu bar (top-right).
2. **Configure viewer path**: Click menu → Preferences → General → set your molecular viewer path.
3. **Convert XYZ → Viewer**:
   - Copy XYZ format coordinates (from terminal, text editor, etc.)
   - Press hotkey (default: `⌘⌥X`)
   - Molecular viewer opens automatically
4. **Convert back to XYZ**:
   - Press hotkey (default: `⌘⌥G`)
   - Paste your structure text in the dialog
   - XYZ format is copied to clipboard

## Configuration

Settings are stored in macOS UserDefaults and persist across sessions:

- `hotkey_xyz_to_gview`: Hotkey for XYZ→viewer (default: `cmd+alt+x`)
- `hotkey_gview_to_xyz`: Hotkey for reverse conversion (default: `cmd+alt+g`)
- `viewer_command`: Path to molecular viewer executable
- `temp_directory`: Where to store temporary files
- `cleanup_delay_seconds`: How long before auto-deleting temp files (default: 5s)
- `log_level`: Logging verbosity (DEBUG/INFO/WARNING/ERROR)
- `log_file_path`: Optional log file location

## Architecture

- **XYZMonitorApp.swift**: SwiftUI app entry point and Settings window
- **AppDelegate.swift**: Menu bar management, hotkey dispatch, file operations
- **Models.swift**: Data structures (Atom, Molecule, ConfigData, etc.)
- **ConverterService.swift**: XYZ↔GJF parsing and generation
- **ClipboardService.swift**: macOS NSPasteboard wrapper
- **HotkeyService.swift**: Global hotkey registration (Carbon framework)
- **ConfigStore.swift**: Configuration persistence (UserDefaults)
- **Logger.swift**: File and console logging
- **ConfigurationView.swift**: SwiftUI preferences UI

## Feature Parity with Windows App

| Feature | Windows | macOS |
|---------|---------|-------|
| Clipboard XYZ import | ✓ | ✓ |
| Open in external viewer | ✓ | ✓ |
| Reverse conversion | ✓ | ✓ |
| Global hotkeys | ✓ | ✓ (subject to macOS permissions) |
| Config UI | ✓ | ✓ |
| Menu bar / Tray | ✓ (tray) | ✓ (menu bar) |
| Auto-temp cleanup | ✓ | ✓ |
| Plugin system | ✓ | — (planned as native extensions) |

## Limitations & Differences

1. **Gaussian Clipboard file (.frg)**: macOS version does not require this Windows-specific binary format. Conversion is text-based.
2. **Global hotkeys**: Requires Accessibility permissions in System Preferences → Security & Privacy.
3. **No .exe plugins**: macOS extensions will follow a different model (Swift/SwiftUI-based).

## Troubleshooting

### Hotkeys don't work
- Check System Preferences → Security & Privacy → Accessibility
- Ensure XYZ Monitor is in the list with "Allow" enabled
- Restart the app after granting permissions

### Viewer doesn't open
- Verify the path in Preferences → General → Viewer Application is correct
- Ensure the viewer application exists and is executable

### Temp files not cleaning up
- Check `temp_directory` setting is writable
- Increase `cleanup_delay_seconds` if viewer is slow to start
- Check logs: `~/Library/Application Support/XYZMonitor/xyz_monitor.log`

## Development

### Run in debug mode:

```bash
swift build -c debug
.build/debug/XYZMonitor
```

### Run tests:

```bash
swift test
```

### View logs:

```bash
tail -f ~/Library/Application\ Support/XYZMonitor/xyz_monitor.log
```

## License

Same as parent xyzTrickGview2 repository.

## Upstream Acknowledgement

This project originated from ideas and workflows in the upstream `xyzTrickGview2` project.
If you need the original Windows-oriented implementation, refer to the upstream repository.

---

**Version**: 1.0.0  
**Platform**: macOS 12.0+  
**Language**: Swift 5.9+ (SwiftUI)
