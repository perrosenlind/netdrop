# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NetDrop is a native macOS SwiftUI application for SCP file transfers, targeting network engineers who work with devices that only support SCP (FortiGates, Cisco, etc.). It wraps the native `scp` CLI via `Process()` rather than reimplementing the protocol.

## Tech Stack

- **Language:** Swift 5.9+
- **UI:** SwiftUI (macOS 14+ / Sonoma)
- **Architecture:** @Observable models + SwiftUI views
- **SCP/SSH:** System `scp`/`ssh` via `Process()` (Foundation)
- **Data persistence:** JSON files via Codable in `~/Library/Application Support/NetDrop/`

## Build & Run

```bash
# Build from command line
xcodebuild -project NetDrop.xcodeproj -scheme NetDrop -configuration Debug build

# Run (open in Xcode)
open NetDrop.xcodeproj
# Then Cmd+R to run

# Or build and run via xcodebuild
xcodebuild -project NetDrop.xcodeproj -scheme NetDrop -configuration Debug build && \
  open build/Debug/NetDrop.app
```

## Architecture

```
NetDrop/
├── NetDropApp.swift          # App entry point
├── Models/                   # Data models (Codable structs)
│   ├── Favorite.swift        # Connection profile model
│   ├── TransferTask.swift    # Transfer job model
│   └── TransferLog.swift     # Transfer history entry
├── Services/                 # Backend logic
│   ├── SCPService.swift      # Process()-based SCP wrapper
│   ├── SSHService.swift      # Process()-based SSH wrapper
│   ├── FavoritesStore.swift  # Favorites JSON persistence + CRUD
│   └── TransferLogStore.swift# Transfer history persistence
└── Views/                    # SwiftUI views
    ├── ContentView.swift     # Main NavigationSplitView layout
    ├── Sidebar/              # Favorites sidebar views
    ├── Transfer/             # File transfer views
    └── Settings/             # Settings views
```

**Data flow:** SwiftUI views observe `@Observable` model classes (stores). Stores handle persistence to JSON files. Services wrap system `scp`/`ssh` commands via `Process()`.

## Key Patterns

- **Observation:** Uses Swift 5.9 `@Observable` macro (not legacy ObservableObject/Published)
- **Async:** Transfer operations use Swift concurrency (async/await + Process)
- **Persistence:** All data stored as JSON in `~/Library/Application Support/NetDrop/`
- **SCP integration:** Shell out to system `scp` with arguments built from Favorite model fields

## Xcode Project Generation

The Xcode project is generated from `project.yml` using [xcodegen](https://github.com/yonaskolb/XcodeGen). After adding or removing Swift files, regenerate with:

```bash
xcodegen generate
```

Always use `clean build` to clear caches so changes are visible:

```bash
xcodebuild -project NetDrop.xcodeproj -scheme NetDrop -configuration Debug clean build
```

## Build Phases

Phased roadmap in `plan.md`. Currently building Phase 1 (MVP): favorites CRUD, single-file SCP upload/download, basic transfer log.

## Workflow Rules

- Always update `README.md` when making user-visible changes
- Always push to git after completing work
