<h1 align="center">
  <img src="Clipboard/EasyClip_logo.png" width="80" alt="EasyClip" /><br>
  EasyClip
</h1>

<p align="center">
  <strong>A macOS menu bar clipboard history manager</strong>
</p>

<p align="center">
  Auto-capture · Search & Recall · One-click Paste · Local & Private
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2010.15%2B-lightgrey" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.1%2B-orange" alt="Swift">
  <img src="https://img.shields.io/badge/arch-arm64%20%7C%20x86__64-blue" alt="Arch">
</p>

<p align="center">
  🌐 <a href="README.md">中文</a> · <a href="README.en.md">English</a>
</p>

---

## What Is This

**EasyClip** is a lightweight macOS clipboard history manager that lives in your menu bar. It automatically saves every piece of text and image you copy.

macOS only remembers your most recent copy. Copy something new, and the old one is gone. EasyClip keeps a running history of everything you copy — text or images — so you can bring it back with a single click.

**100% local. No network requests. No data ever leaves your machine.**

## Features

| Feature | Description |
|---------|-------------|
| 🔄 **Auto-Capture** | Real-time clipboard monitoring — text and images saved automatically, no manual steps |
| 📋 **Card View** | Text cards preview 3 lines, image cards show 160px thumbnails, sorted newest-first |
| 📌 **Pin** | Pin important items to the top — they stay forever, exempt from auto-cleanup |
| 🔍 **Search** | Real-time keyword filtering across all text entries |
| 👆 **Paste** | Click any card to write it back to the clipboard, then Cmd+V to paste |
| 🖼️ **Preview** | Hover an image and press Space for native Quick Look at full resolution |
| ⏱️ **Retention** | Default 1 day, configurable to 1/3/5 days — expired items auto-cleaned |
| 🗑️ **Delete & Clear** | Single-item delete + clear all (pinned items are always protected) |
| 🚀 **Launch at Login** | One-click toggle in Settings, auto-starts on reboot |
| 🌓 **Dark Mode** | Follows system appearance automatically |
| 🍎 **Compatibility** | macOS 10.15 Catalina and above, Intel + Apple Silicon universal binary |

## Installation

### Direct Download

Download the latest `EasyClip.app` from the [Releases](../../releases) page and drag it into `/Applications`.

### Build from Source

```bash
# 1. Make sure Xcode is installed (via App Store)
# 2. Select Xcode developer directory
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# 3. Build Debug
xcodebuild -project Clipboard.xcodeproj -scheme EasyClip -configuration Debug

# 4. Run
open ~/Library/Developer/Xcode/DerivedData/Clipboard-*/Build/Products/Debug/EasyClip.app
```

Build a universal Release binary:

```bash
xcodebuild -project Clipboard.xcodeproj \
  -scheme EasyClip \
  -configuration Release \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO
```

## Usage

1. Launch EasyClip — an icon appears in your menu bar
2. **Left-click** the icon → opens the clipboard history panel
3. **Right-click** the icon → Settings / Quit
4. Click any card → content written back to clipboard → paste as usual
5. Hover over a card → Pin ⬆️ and Delete 🗑️ buttons appear
6. Hover over an image → click Preview 👀 or press Space

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 5.1+ |
| UI | SwiftUI 1.0 + AppKit (NSPopover) |
| Data | Core Data (SQLite + External Storage) |
| Clipboard | NSPasteboard, 0.5s polling |
| Images | NSImage + NSBitmapImageRep (lossless PNG) |
| Launch | LaunchAgent (launchctl) |
| Preview | Quartz QLPreviewPanel |

## Why macOS 10.15?

Modern SwiftUI APIs (`@main`, `Image(systemName:)`, `@AppStorage`, `MenuBarExtra`, etc.) mostly require macOS 11+. EasyClip uses 10.15-compatible alternatives throughout so older Macs are not left out:

- `NSApplicationDelegate` instead of `@main`
- Unicode character icons instead of SF Symbols
- `NSStatusBar` + `NSPopover` instead of `MenuBarExtra`
- `LaunchAgent` instead of `SMAppService`

See [Technical Spec](docs/technical-spec.md) for more details.

## Project Structure

```
├── Clipboard/
│   ├── main.swift                     # App entry point
│   ├── AppDelegate.swift              # Menu bar + popover + settings
│   ├── Models/
│   │   ├── ContentType.swift          # Content type enum
│   │   └── ClipboardItem+CoreData*.swift
│   ├── Services/
│   │   ├── ClipboardMonitor.swift     # Clipboard polling
│   │   ├── PersistenceController.swift # Data persistence
│   │   ├── RetentionManager.swift     # Expiry cleanup
│   │   └── AutoStartManager.swift     # Launch at login
│   ├── ViewModels/
│   │   └── ClipboardViewModel.swift   # Business logic
│   ├── Views/
│   │   ├── ContentView.swift          # Main panel
│   │   ├── ClipboardCardView.swift    # Text / image cards
│   │   ├── SearchBarView.swift        # Search field
│   │   ├── EmptyStateView.swift       # Empty state
│   │   ├── FooterView.swift           # Bottom action bar
│   │   └── Settings/SettingsView.swift # Settings window
│   └── Helpers/
│       ├── ColorTheme.swift           # Dynamic colors (dark mode)
│       ├── SystemIcon.swift           # Unicode icons
│       ├── ImageResizer.swift         # Thumbnail generation
│       └── DateFormatter+Relative.swift
├── docs/
│   ├── requirements.md                # Requirements doc
│   ├── technical-spec.md              # Technical spec
│   ├── design-spec.md                 # Design spec
│   ├── execution-steps.md             # Development checklist
│   └── prd.md                         # Product requirements doc
└── devlog/                            # Development logs
```

## Docs

- [Requirements](docs/requirements.md) — Functional & non-functional requirements
- [PRD](docs/prd.md) — User stories & acceptance criteria
- [Technical Spec](docs/technical-spec.md) — Architecture, data model, key mechanisms
- [Design Spec](docs/design-spec.md) — Colors, typography, spacing, components
- [Development Checklist](docs/execution-steps.md) — Phase-by-phase progress

## FAQ

**Q: Why aren't file copies recorded?**
This is intentional. File copies store file path strings on the clipboard — recording them is noisy and rarely useful.

**Q: Why doesn't pasting from EasyClip get re-recorded?**
EasyClip uses a `skipNextPasteboardChange` flag internally to skip clipboard changes caused by its own paste-back.

**Q: Where is my data stored?**
All data is stored locally via Core Data (SQLite + external image files). Nothing is ever uploaded anywhere.

**Q: Does it support iCloud sync?**
Not in v1.0. This may be considered in a future release.

## License

MIT License

---

<p align="center">
  <sub>Built with ❤️ on macOS</sub>
</p>
