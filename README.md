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

Click the menu bar icon to open the popover. It updates instantly as `mon` writes new status.

## Features

- **Filter tabs** — Running / Done / All
- **Live stats** — CPU % and memory with animated progress bars
- **Output preview** — last 4 lines of stdout/stderr per process
- **Log overlay** — double-click any row to open a full scrollable log
- **ANSI stripping** — color codes and `\r` from tqdm are cleaned automatically
- **Menu bar title** — shows `python · 45% · 1.1GB · 0:12` for the active process

## How it works

`mon` launches your command through a **pseudo-terminal** (pty) so programs flush output naturally instead of buffering until exit. It writes a JSON status file to `~/.process_monitor/<pid>.json` every 3 seconds and streams all output to `~/.process_monitor/<pid>.log`.

`ProcessMonitor.app` watches that directory with **FSEvents** (`FSEventStreamCreate`) and reacts within ~200ms whenever `mon` writes a new status file. It decodes each JSON file, reads the tail of the log, strips ANSI escape codes, and renders everything in the SwiftUI popover.

## Project structure

```
mon                              # CLI wrapper — copy to /usr/local/bin/
ProcessMonitor/
  ProcessMonitor.xcodeproj/
  ProcessMonitor/
    ProcessMonitorApp.swift      # App entry point + MenuBarExtra setup
    MainView.swift               # Popover UI, filter tabs, rows, log overlay
    Models.swift                 # ProcessInfo struct + computed properties
    ProcessStore.swift           # FSEvents watcher, ANSI strip
    Assets.xcassets/
```

## Requirements

- macOS 14+ (Sonoma) — uses `MenuBarExtra` with `.window` style
- Python 3 — for the `mon` CLI
- Xcode 16+ — to build the app
