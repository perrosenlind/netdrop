# NetDrop — Build Plan

## Concept

A lightweight macOS GUI for SCP transfers, aimed at network engineers who work with devices that only support SCP (FortiGates, Cisco, etc.). Wraps the native `scp` CLI under the hood — no need to reimplement the protocol.

---

## Core Features

### 1. Connection Favorites
- Saved device profiles: name, host/IP, port, username, auth method (key or password)
- Tags/groups (e.g. "Lab", "Production", "Customer-EKN")
- Quick-connect from a sidebar or dropdown
- Import/export favorites as JSON for portability

### 2. File Transfer
- Multi-file and folder upload (recursive via `scp -r`)
- Multi-file download
- Drag-and-drop onto the app window to initiate upload
- Transfer queue with progress indicators (parse scp's `-v` or use `ssh2` for granular progress)
- Cancel/retry individual transfers

### 3. Remote File Browser
- List remote directory contents via SSH (`ls -la` over SSH session)
- Navigate folders, create directories
- Single-pane with breadcrumb path (like Cyberduck) — keep it simple
- Context menu: download, delete, rename

### 4. Transfer History & Log
- Log of all transfers with timestamp, source, destination, status
- Filterable by device/date
- Raw SCP/SSH output viewable for troubleshooting

### 5. SSH Key Management
- Pick key from `~/.ssh/` or browse for custom key path
- Per-favorite key assignment
- Support for passphrase-protected keys (via ssh-agent integration)

---

## Tech Stack

**Swift + SwiftUI** — native macOS app

- Native macOS look and feel (NavigationSplitView, toolbars, context menus)
- Drag-and-drop integration with Finder
- Menubar icon support
- Small binary, low memory footprint
- Sandboxing and notarization straightforward
- SSH/SCP via `Process()` wrapping system commands

---

## Architecture

```
┌─────────────────────────────────┐
│       SwiftUI Frontend          │
│  (Favorites, File Browser, UI) │
└──────────────┬──────────────────┘
               │ @Observable models
┌──────────────▼──────────────────┐
│        Swift Backend            │
│  ┌───────────┐ ┌──────────────┐ │
│  │ SCPService│ │ FavoritesStore│ │
│  │ (Process) │ │ (JSON file)  │ │
│  └───────────┘ └──────────────┘ │
│  ┌───────────┐ ┌──────────────┐ │
│  │ SSHService│ │TransferLog   │ │
│  │ (Process) │ │ (JSON file)  │ │
│  └───────────┘ └──────────────┘ │
└─────────────────────────────────┘
               │
        ┌──────▼──────┐
        │  scp / ssh  │
        │  (system)   │
        └─────────────┘
```

### Backend approach:

**Wrap system `scp`/`ssh` via Process()**
- Spawn `scp` as a child process
- Parse output for progress
- Uses system SSH config and ssh-agent automatically
- Future: optionally migrate to NMSSH or libssh2 Swift binding for granular control

---

## Data Storage

- **Favorites**: JSON file in `~/Library/Application Support/NetDrop/favorites.json`
- **Transfer history**: JSON file in the same directory (MVP), migrate to SQLite later if needed
- **Settings**: JSON file (default download path, theme, etc.)

---

## UI Layout

```
┌──────────────────────────────────────────────┐
│  ☰  [Quick Connect ▾]           [⚙ Settings] │
├────────────┬─────────────────────────────────┤
│            │  📁 /home/admin/                │
│ ★ Favorites│  ┌─────────────────────────────┐│
│            │  │ firmware/                   ││
│ ▸ Lab      │  │ config-backup-2026.conf     ││
│   FGT-01   │  │ debug-log.txt              ││
│   FGT-02   │  │                             ││
│ ▸ Prod     │  │                             ││
│   Core-SW  │  │                             ││
│            │  └─────────────────────────────┘│
│            ├─────────────────────────────────┤
│            │  Transfer Queue                 │
│            │  ↑ firmware.out ████░░ 67%      │
│            │  ✓ backup.conf     Complete     │
└────────────┴─────────────────────────────────┘
```

---

## Build Phases

### Phase 1 — MVP (get it working)
- [x] Create SwiftUI macOS app project
- [x] Favorites CRUD (add/edit/delete connections, stored in JSON)
- [x] Connect to device via system `scp`
- [x] Single file upload and download
- [x] Basic transfer log
- [x] Quick connect

### Phase 2 — Usable daily driver
- [x] Multi-destination upload (same file to multiple devices at once)
- [x] Remote file browser (ls via SSH)
- [x] Multi-file upload with queue
- [x] Drag-and-drop upload
- [x] Transfer progress parsing
- [x] SSH key selection per favorite
- [x] Favorite groups/tags

### Phase 3 — Polish
- [x] Transfer history with search/filter
- [x] Keyboard shortcuts (Cmd+N new connection, Cmd+U upload, etc.)
- [x] Menu bar quick-upload (drop file on menubar icon → pick favorite → transfer)
- [ ] Auto-reconnect on timeout
- [ ] Dark/light theme matching macOS system setting
- [x] Notifications on transfer complete

### Phase 4 — Nice to have
- [ ] Bulk config backup scheduler (cron-like, SSH in and pull configs)
- [ ] Side-by-side diff for config files
- [ ] Integration with FortiManager API for device inventory import
- [ ] Homebrew cask for distribution
