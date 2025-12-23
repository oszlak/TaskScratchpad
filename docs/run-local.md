# Development Guide

## Requirements

- **macOS 14 (Sonoma)** or later
- **Swift 5.9+** / Xcode 15+ command line tools

## Quick Start

```bash
# Clone and enter directory
git clone https://github.com/YOUR_USERNAME/TaskScratchpad.git
cd TaskScratchpad

# Run in debug mode
swift run
```

## Build Commands

| Command | Description |
|---------|-------------|
| `swift run` | Build and run (debug) |
| `swift build` | Build only (debug) |
| `swift build -c release` | Build release binary |
| `swift test` | Run unit tests |
| `./scripts/run-ui-tests.sh` | Run UI tests (XCUITest) |
| `swift package clean` | Clean build artifacts |

## Testing

### Unit Tests

```bash
# Run all unit tests
swift test

# Run with coverage
swift test --enable-code-coverage
```

### UI Tests (XCUITest)

The project includes XCUITest-based UI tests for automated UI verification.

```bash
# Run UI tests (requires Xcode)
./scripts/run-ui-tests.sh

# Or manually with xcodebuild
xcodebuild test \
    -project TaskScratchpad.xcodeproj \
    -scheme TaskScratchpad \
    -destination 'platform=macOS'
```

**Note:** UI tests require:
- Xcode (not just command line tools)
- Accessibility permissions may be needed
- Install `xcbeautify` for prettier output: `brew install xcbeautify`

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + N` | Focus quick-add input |
| `Cmd + K` | Clear all completed tasks |
| `Escape` | Return focus to input |
| `Option + Space` | Global show/hide (requires Accessibility permission) |

## Global Hotkey Setup

For `Option + Space` to work:

1. **System Settings → Privacy & Security → Accessibility**
2. Click **+** and add Terminal (or the app itself)
3. Toggle permission **ON**

## Data Location

SwiftData stores data in:
```
~/Library/Application Support/TaskScratchpad/
```

To reset all data:
```bash
rm -rf ~/Library/Application\ Support/TaskScratchpad
```

## Troubleshooting

### Build fails with toolchain errors

Ensure you're using Xcode's toolchain:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### App doesn't receive keyboard focus

The app activates itself on launch. If focus is lost, click the window or press `Cmd + N`.

### Global hotkey doesn't work

Grant Accessibility permission (see above). The hotkey only works when the app is running.

## Creating a Release

See [distribution.md](distribution.md) for packaging instructions.
