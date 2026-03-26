# NetDrop

A lightweight native macOS app for SCP file transfers, built for network engineers who work with devices that only support SCP (FortiGates, Cisco switches, etc.).

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)

## Features

- **Connection Favorites** — Save device profiles with host, port, username, SSH key, and group. Persisted locally as JSON.
- **Quick Connect** — Connect to any device on the fly (Cmd+K) without saving a favorite. Optionally save it after connecting.
- **File Upload & Download** — Single-file SCP transfers via the native `scp` command. Browse local files or specify remote paths.
- **Transfer Log** — Live progress for active transfers plus a history of recent transfers with status and timestamps.
- **SSH Key Support** — Per-connection key assignment, SSH agent integration, or password auth.

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
- [ ] Phase 2 — Remote file browser, multi-file queue, drag-and-drop, progress parsing
- [ ] Phase 3 — History search, keyboard shortcuts, menubar quick-upload, theming
- [ ] Phase 4 — Config backup scheduler, diff viewer, FortiManager integration

## License

MIT
