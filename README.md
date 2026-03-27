# NetDrop

A lightweight native macOS app for SCP file transfers, built for network engineers who work with devices that only support SCP (FortiGates, Cisco switches, etc.).

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)

## Features

- **Password & Key Authentication** — Connect with username/password (via `sshpass`), SSH key, or SSH agent. Passwords stored securely in macOS Keychain with automatic prompt if missing.
- **Connection Favorites** — Save device profiles with host, port, username, auth method. Organize into collapsible folders. Duplicate IPs allowed across folders for overlapping environments. Double-click to connect.
- **Quick Connect** — Connect to any device on the fly (Cmd+K) with username and password. Save as a favorite after connecting.
- **Multi-File Upload** — Select multiple files or drag-and-drop them onto the app to queue transfers.
- **Multi-Destination Upload** — Push the same file(s) to multiple devices at once (Cmd+Shift+M). Import a list of IPs from a text/CSV file with shared credentials, or select from your favorites.
- **Remote File Browser** — Browse remote directories via SSH. Navigate folders, download files, delete with context menu.
- **Connection Status** — Live green/red indicator showing if a device is reachable, with friendly error messages. Auto-reconnects every 15 seconds when offline.
- **Drag & Drop** — Drop files onto the transfer area to start uploading immediately.
- **Transfer Progress** — Live SCP progress output streamed to the transfer queue as files move.
- **Transfer Log** — History of all transfers with search and status filtering (All/Completed/Failed).
- **SSH Key Picker** — Browse for key files, per-connection assignment, SSH agent integration.
- **Sidebar Folders** — Create, rename, and delete folders in the sidebar. Move favorites between folders via context menu. Collapsible with device count.
- **Menubar Quick-Upload** — Drop files onto the menubar icon to upload without opening the main window.
- **Keyboard Shortcuts** — Cmd+N (new connection), Cmd+K (quick connect), Cmd+U (upload), Cmd+Shift+M (multi-device), Cmd+, (settings).
- **Notifications** — macOS notifications on transfer complete or failure with error details.
- **Dark/Light Mode** — System, Light, or Dark theme via Settings (Cmd+,).
- **Config Backup Scheduler** — Schedule automatic config backups via SCP on intervals (15min to daily). FortiGate support with `sys_config` download and legacy SCP protocol (`-O`). Generic device type for custom remote paths. Configurable backup directory in Settings.
- **Config Restore** — Restore config files to devices via SCP upload. FortiGate restores to `fgt-restore-config` with reboot warning. Right-click any backup result to restore.
- **Config Viewer** — View config files with FortiOS syntax highlighting using native NSTextView. Color-coded keywords (`config`, `set`, `edit`, `end`), strings, IP addresses, and values. Built-in Cmd+F search. Right-click backup results or use ad-hoc backup from sidebar.
- **Ad-hoc Config Backup** — Right-click any favorite in the sidebar to backup its config via SCP. Choose save location, then view the config immediately with syntax highlighting.
- **Side-by-Side Diff** — Compare two config files with LCS-based diff. Color-coded added/removed/modified lines, line numbers, summary stats. Pick from backup history or browse local files.
- **Welcome Screen** — Action cards and shortcut reference when no connection is selected.

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ (for building)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (for project generation)
- [sshpass](https://sourceforge.net/projects/sshpass/) (for password authentication)

## Getting Started

```bash
# Install dependencies
brew install xcodegen
brew install hudochenkov/sshpass/sshpass

# Generate Xcode project
xcodegen generate

# Open in Xcode and run (Cmd+R)
open NetDrop.xcodeproj
```

Or build from the command line:

```bash
xcodebuild -project NetDrop.xcodeproj -scheme NetDrop -configuration Debug build
```

## Testing

```bash
xcodebuild -project NetDrop.xcodeproj -scheme NetDropTests -configuration Debug test
```

84 unit tests covering all models, services, and stores:

| Suite | Tests | Coverage |
|---|---|---|
| IPListParserTests | 15 | All parsing formats, comments, dedup, edge cases |
| RemoteFileEntryTests | 10 | Icons for every file type, formatted sizes |
| FavoritesStoreTests | 11 | Full CRUD, groups, folder create/rename/delete, duplicate IPs, selection clearing |
| TransferManagerTests | 7 | Single/multi upload, multi-dest, cancel, clear |
| FavoriteModelTests | 5 | Defaults (password auth), Codable for all auth types, equality |
| AppSettingsTests | 5 | All appearance modes, persistence |
| SCPServiceTests | 5 | Upload/download with real scp, progress, auth |
| SSHServiceTests | 4 | ls/mkdir/rm/rename with real ssh |
| TransferTaskTests | 4 | Init, cancel, process attachment, properties |
| TransferRecordTests | 4 | Defaults, Codable, directions, statuses |
| BackupJobTests | 6 | Defaults, device types (FortiGate/Generic), Codable round-trip, result model, statuses |
| DiffEngineTests | 9 | Identical, added, removed, modified, empty, summary, large configs |

## Architecture

NetDrop is a pure SwiftUI app. It wraps the system `scp` and `ssh` commands via `Process()`, using `sshpass` for password authentication. No SSH libraries are bundled.

- **Frontend:** SwiftUI with `NavigationSplitView`, native macOS controls
- **Backend:** `@Observable` Swift models, JSON persistence, `Process()`-based SCP/SSH
- **Data:** Favorites and settings in `~/Library/Application Support/NetDrop/`, passwords in macOS Keychain

## Security

Passwords are **never stored in plaintext files**. All credentials are saved to the macOS Keychain using the Security framework (`SecItemAdd`/`SecItemCopyMatching`) with `kSecAttrAccessibleWhenUnlocked` protection. Favorite profiles (host, port, username, auth method) are stored as JSON — passwords are not included in the JSON file.

## Roadmap

See [plan.md](plan.md) for the full phased roadmap.

- [x] Phase 1 — MVP: Favorites, single-file transfer, transfer log, quick connect
- [x] Phase 2 — Remote file browser, multi-file queue, drag-and-drop, multi-destination, progress parsing
- [x] Phase 3 — History search, keyboard shortcuts, menubar quick-upload, notifications, dark/light mode, password auth
- [x] Phase 4 — Config backup scheduler, diff viewer, Homebrew cask

## Installation (Homebrew)

Once a release is published:

```bash
brew install --cask perrosenlind/tap/netdrop
```

Or build from source (see Getting Started above).

## Release Build

```bash
./scripts/build-release.sh
# Then create a GitHub release:
gh release create v0.1.0 NetDrop.app.zip --title 'NetDrop v0.1.0'
```

## License

MIT
