# ProcessMonitor

A native macOS menu bar app that monitors any terminal process in real time — CPU, memory, elapsed time, and live output.

## Overview

ProcessMonitor has two parts:

| Component | What it does |
|---|---|
| `mon` | CLI wrapper — runs any command and streams live status to `~/.process_monitor/` |
| `ProcessMonitor.app` | Native SwiftUI menu bar app — reads those files and shows them in a popover |

## Install

### 1. Install the `mon` CLI

```bash
sudo cp mon /usr/local/bin/mon
chmod +x /usr/local/bin/mon
```

### 2. Build the macOS app

Open `ProcessMonitor/ProcessMonitor.xcodeproj` in Xcode, then press **⌘R** to build and run.

> **Sandbox note:** In Xcode → Signing & Capabilities, make sure **App Sandbox is disabled** so the app can read from `~/.process_monitor/`.

## Usage

Prefix any long-running command with `mon`:

```bash
mon python train.py --epochs 100
mon --name "Build" make all
mon npm run build
mon pytest
mon ./server.sh
```

Click the menu bar icon to open the popover. It auto-refreshes every 3 seconds.

## Features

- **Filter tabs** — Running / Done / All
- **Live stats** — CPU % and memory with animated progress bars
- **Output preview** — last 4 lines of stdout/stderr per process
- **Log overlay** — double-click any row to open a full scrollable log
- **ANSI stripping** — color codes and `\r` from tqdm are cleaned automatically
- **Menu bar title** — shows `python · 45% · 1.1GB · 0:12` for the active process

## How it works

`mon` launches your command through a **pseudo-terminal** (pty) so programs flush output naturally instead of buffering until exit. It writes a JSON status file to `~/.process_monitor/<pid>.json` every 3 seconds and streams all output to `~/.process_monitor/<pid>.log`.

`ProcessMonitor.app` polls that directory on a 3-second `Timer`, decodes each JSON file, reads the tail of the log, strips ANSI escape codes, and renders everything in the SwiftUI popover.

## Project structure

```
mon                              # CLI wrapper — copy to /usr/local/bin/
ProcessMonitor/
  ProcessMonitor.xcodeproj/
  ProcessMonitor/
    ProcessMonitorApp.swift      # App entry point + MenuBarExtra setup
    MainView.swift               # Popover UI, filter tabs, rows, log overlay
    Models.swift                 # ProcessInfo struct + computed properties
    ProcessStore.swift           # File watcher, timer, ANSI strip
    Assets.xcassets/
extras/
  process_monitor.5s.sh          # SwiftBar plugin (alternative to native app)
  process-monitor.jsx            # Übersicht desktop widget (alternative)
  training_status_writer.py      # Optional PyTorch metrics helper
```

## Extras

The `extras/` folder contains alternative frontends built during development:

- **SwiftBar plugin** (`process_monitor.5s.sh`) — lightweight menu bar plugin using [SwiftBar](https://github.com/swiftbar/SwiftBar), no Xcode required
- **Übersicht widget** (`process-monitor.jsx`) — floating desktop widget using [Übersicht](https://tracesof.net/uebersicht/)
- **PyTorch helper** (`training_status_writer.py`) — writes training metrics (loss, accuracy, epoch) directly without wrapping with `mon`

## Requirements

- macOS 14+ (Sonoma) — uses `MenuBarExtra` with `.window` style
- Python 3 — for the `mon` CLI
- Xcode 16+ — to build the app
