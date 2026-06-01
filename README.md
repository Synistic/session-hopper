# Session Hopper

Session Hopper is a native macOS launcher for jumping back into recent Claude Code sessions from the menu bar.

It scans your local Claude Code session files, shows recent sessions, and resumes a selected session in Ghostty with the original working directory.

![macOS](https://img.shields.io/badge/macOS-14%2B-0a0a0a)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![License](https://img.shields.io/badge/license-MIT-0c8c5e)

## What It Does

- Lists recent Claude Code sessions from `~/.claude/projects`
- Opens a session in Ghostty from the correct project directory
- Runs Claude Code with `--dangerously-skip-permissions`
- Opens the project folder in Finder
- Copies a session ID to the clipboard
- Provides both a desktop window and a macOS menu bar item

## Safety Notice

Session Hopper intentionally resumes Claude Code with:

```bash
claude --dangerously-skip-permissions --resume <session-id>
```

That means Claude Code bypasses permission prompts. This is useful for a trusted local workflow, but it is not a safe default for shared machines, unfamiliar repositories, or untrusted session data.

Use this app only if you understand that tradeoff.

## Requirements

- macOS 14 or newer
- Xcode or the Xcode command line toolchain
- [Ghostty](https://ghostty.org/) installed at `/Applications/Ghostty.app`
- Claude Code CLI available at `~/.local/bin/claude`
- Existing Claude Code sessions in `~/.claude/projects`

## Quick Start

Clone and run:

```bash
git clone https://github.com/Synistic/session-hopper.git
cd session-hopper
./script/build_and_run.sh
```

The script builds a SwiftPM executable, stages a local `.app` bundle in `dist/SessionHopper.app`, and launches it.

To copy the app to your Desktop:

```bash
cp -R dist/SessionHopper.app ~/Desktop/SessionHopper.app
```

## Development

Run the test suite:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test
```

Build the app:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build
```

Build and verify launch:

```bash
./script/build_and_run.sh --verify
```

## Architecture

Session Hopper is split into a small SwiftUI app target and a testable core library.

- `SessionHopperCore` scans Claude Code session metadata, builds launcher commands, and owns reload state.
- `SessionHopper` renders the desktop window, installs the AppKit menu bar item, and generates the custom icon.
- `script/build_and_run.sh` builds a real macOS `.app` bundle from SwiftPM output.

The app reads only session metadata fields such as `sessionId`, `cwd`, `timestamp`, and `gitBranch`. It does not parse conversation content.

## Menu Bar Icon

The custom icon uses Daniel Schmilinski's accent green `#0c8c5e` with a subtle teal gradient. The icon combines a terminal prompt, cursor, and small spark to represent session hopping.

## License

MIT
