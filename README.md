# Task Scratchpad

A minimal, beautiful macOS task manager built with SwiftUI and SwiftData. Designed for quick capture and zero-friction task management.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

<!-- 
Add a screenshot here:
![Task Scratchpad Screenshot](docs/screenshot.png)
-->

## ✨ Features

- **Zero-Friction Input** — Quick-add tasks with a prominent input field that auto-focuses on launch
- **Subtasks** — Break down tasks into smaller actionable items with progress tracking
- **Rich Context** — Expandable notes area with automatic link/email detection
- **Color Coding** — Assign colors to tasks for visual organization
- **Drag & Drop Reordering** — Organize tasks by dragging them into position
- **Smart Sorting** — Active tasks stay at top, completed tasks sink to bottom
- **Float on Top** — Keep the window visible above other apps
- **Keyboard Shortcuts** — `Cmd+N` to focus input, `Cmd+K` to clear completed
- **Global Hotkey** — `Option+Space` to show/hide from anywhere (requires Accessibility permission)
- **Native Look** — Translucent sidebar-style background, SF Symbols, spring animations
- **Persistent** — All data saved locally with SwiftData

## 📥 Installation

### Download Release

Download the latest `.dmg` from [Releases](../../releases), open it, and drag Task Scratchpad to Applications.

### Build from Source

**Requirements:**
- macOS 14 (Sonoma) or later
- Xcode 15+ or Swift 5.9+ command line tools

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/TaskScratchpad.git
cd TaskScratchpad

# Build and run
swift run

# Or build release
swift build --configuration release
```

### Create Distributable DMG

```bash
./scripts/create-dmg.sh
```

Output: `dist/TaskScratchpad-0.0.1.dmg`

## 🎯 Usage

| Action | How |
|--------|-----|
| **Add task** | Type in the input field, press Return |
| **Complete task** | Click the circle |
| **Expand task** | Click the task title |
| **Add subtask** | Expand task → type in "Add subtask..." |
| **Change color** | Hover → click the colored dot |
| **Delete task** | Hover → click × |
| **Reorder** | Drag tasks up/down |
| **Focus input** | `Cmd + N` |
| **Clear completed** | `Cmd + K` |
| **Show/hide app** | `Option + Space` (global) |
| **Float on top** | Menu → Scratchpad → Float on Top |

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + N` | Focus the quick-add input |
| `Cmd + K` | Clear all completed tasks |
| `Escape` | Return focus to input |
| `Option + Space` | Global show/hide (requires Accessibility permission) |

## 🔐 Permissions

For the global hotkey (`Option + Space`) to work:

1. Open **System Settings → Privacy & Security → Accessibility**
2. Click **+** and add Task Scratchpad (or Terminal if running via `swift run`)
3. Toggle the permission **ON**

## 🏗️ Project Structure

```
TaskScratchpad/
├── Package.swift                 # SwiftPM manifest
├── Sources/
│   └── TaskScratchpad/
│       └── main.swift            # Single-file SwiftUI app
├── scripts/
│   └── create-dmg.sh             # Build & package script
└── docs/
    ├── distribution.md           # Distribution guide
    └── run-local.md              # Development guide
```

## 🛠️ Tech Stack

- **SwiftUI** — Declarative UI framework
- **SwiftData** — Persistence (replaces Core Data)
- **@Observable** — Modern state management (macOS 14+)
- **NSVisualEffectView** — Native translucent background
- **NSEvent** — Global hotkey monitoring

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Icons from [SF Symbols](https://developer.apple.com/sf-symbols/)
- Inspired by minimal productivity tools

---

Made with ❤️ for macOS

