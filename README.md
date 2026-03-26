# NetDrop

A lightweight native macOS app for SCP file transfers, built for network engineers who work with devices that only support SCP (FortiGates, Cisco switches, etc.).

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)

## Features

- **Connection Favorites** — Save device profiles with host, port, username, SSH key, and group. Persisted locally as JSON.
- **Quick Connect** — Connect to any device on the fly (Cmd+K) without saving a favorite. Optionally save it after connecting.
- **Multi-File Upload** — Select multiple files or drag-and-drop them onto the app to queue transfers.
- **Multi-Destination Upload** — Push the same file(s) to multiple devices at once (Cmd+Shift+M). Select target devices from your favorites.
- **Remote File Browser** — Browse remote directories via SSH. Navigate folders, download files, delete with context menu.
- **Drag & Drop** — Drop files onto the transfer area to start uploading immediately.
- **Transfer Progress** — Live SCP progress output streamed to the transfer queue as files move.
- **Transfer Log** — History of all transfers with search and status filtering.
- **SSH Key Picker** — Browse for key files, per-connection assignment, SSH agent integration.
- **Favorite Groups** — Organize connections into groups with quick-assign buttons.
- **Menubar Quick-Upload** — Drop files onto the menubar icon to upload without opening the main window.
- **Keyboard Shortcuts** — Cmd+N (new connection), Cmd+K (quick connect), Cmd+U (upload), Cmd+Shift+M (multi-device).
- **Notifications** — macOS notifications on transfer complete or failure.
- **Dark/Light Mode** — System, Light, or Dark theme via Settings (Cmd+,).

## Screenshots

*Coming soon*

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ (for building)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Getting Started

```bash
# Install xcodegen
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode and run (Cmd+R)
open NetDrop.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -project NetDrop.xcodeproj -scheme NetDrop -configuration Debug build
```

## Architecture

NetDrop is a pure SwiftUI app with no external dependencies. It wraps the system `scp` and `ssh` commands via `Process()` — no need to bundle SSH libraries.

- **Frontend:** SwiftUI with `NavigationSplitView`, native macOS controls
- **Backend:** `@Observable` Swift models, JSON persistence, `Process()`-based SCP/SSH
- **Data:** Stored in `~/Library/Application Support/NetDrop/`

## Roadmap

See [plan.md](plan.md) for the full phased roadmap.

- [x] Phase 1 — MVP: Favorites, single-file transfer, transfer log, quick connect
- [x] Phase 2 — Remote file browser, multi-file queue, drag-and-drop, multi-destination, progress parsing
- [x] Phase 3 — History search, keyboard shortcuts, menubar quick-upload, notifications
- [ ] Phase 4 — Config backup scheduler, diff viewer, FortiManager integration

## License

MIT
