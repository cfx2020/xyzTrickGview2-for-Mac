# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-04-02

### Added
- Settings window with comprehensive configuration options
  - GView Application path selector with file picker
  - Gaussian Clipboard Path configuration
  - Temporary Directory configuration
  - Cleanup Delay time configuration (customizable input)
- Hotkey capture and configuration interface
  - Visual hotkey recording with real-time feedback ("Recording..." state)
  - Support for custom modifier combinations (⌘, ⌥, ⌃, ⇧)
  - Mutual exclusivity: only one hotkey can be recorded at a time
  - Reset to default button for hotkey restoration
- Improved menu bar display
  - Native macOS shortcut key symbols (⌘, ⌥, etc.) displayed in menu items
  - System-native keyboard shortcut indicators for all menu items
- Focus management system
  - FocusState-based input field management
  - Automatic recording cancellation when input fields are focused
  - Clear visual feedback for interaction states
- About page with version display and external links
  - Dynamic version information from bundle
  - Links to GitHub repositories (macOS and Windows versions)
  - Personal website link

### Changed
- Replaced "Viewer" terminology with "GView" throughout the application
- Menu items now display keyboard shortcuts using system native symbols instead of text descriptions
- Settings window layout optimized for compactness (300px minimum width)
- Improved hotkey field layout from two-column to better organized structure
- Enhanced input field responsiveness and focus handling

### Fixed
- Keyboard shortcut display now properly shows "+" between modifier symbols (e.g., ⌘+⌥+X)
- Settings window properly closes after Save/Cancel actions
- Recording state now correctly cancels when switching between input fields
- Fixed focus state consistency issues between general settings and hotkey capture fields

### Technical Improvements
- Refactored focus management using @FocusState (macOS 13+ compatible)
- Improved NSEvent monitoring for global hotkey capture
- Enhanced timer-based state observation with 0.01s check intervals
- Better separation of concerns between input focus and hotkey recording states
- Cleaned up deprecated toggle-based cancel triggers in favor of state-based management

## [0.1.0] - 2025-10-XX

### Initial Release
- Basic XYZ to Gaussian file conversion
- Reverse conversion (Gaussian to XYZ)
- Menu bar application with global hotkeys (⌘⌥X, ⌘⌥G)
- Clipboard integration for file content transfer
- Basic About page
- macOS 12.0+ support

---

For more information, visit the [GitHub repository](https://github.com/cfx2020/xyzTrickGview2-for-Mac)
