# Contributing to Task Scratchpad

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## 🚀 Getting Started

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/TaskScratchpad.git
   cd TaskScratchpad
   ```
3. **Build** and run:
   ```bash
   swift run
   ```

## 📋 Development Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ or Swift 5.9+ command line tools
- Git

## 🔧 Development Workflow

### Branch Strategy

```
main          ← Production releases only
  ↑
dev           ← Beta versions, integration branch
  ↑
feat/*        ← Feature branches
fix/*         ← Bug fix branches
```

| Branch | Purpose | Merges To |
|--------|---------|-----------|
| `main` | Production releases | — |
| `dev` | Beta/staging, integration | `main` (via PR) |
| `feat/*` | New features | `dev` (via PR) |
| `fix/*` | Bug fixes | `dev` or `main` (hotfix) |

### Branch Naming

- `feat/description` — New features
- `fix/description` — Bug fixes
- `docs/description` — Documentation updates
- `refactor/description` — Code refactoring

### Commit Messages

Use semantic commit messages:

```
feat: add drag-and-drop reordering for tasks
fix: resolve keyboard focus issue in notes field
docs: update installation instructions
refactor: simplify TaskStore state management
```

Add `[no-release]` to skip CI release:
```
refactor: split main.swift into modules [no-release]
```

### Pull Request Process

1. Create a feature branch from `dev`
2. Make your changes
3. Test thoroughly on macOS
4. Update documentation if needed
5. Submit a PR to `dev` with a clear description
6. After testing in `dev`, maintainers merge to `main` for release

## 🏗️ Code Style

### Swift Guidelines

- Use Swift's standard naming conventions
- Prefer `let` over `var` when possible
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small

### SwiftUI Patterns

- Use `@Observable` for state management
- Prefer composition over inheritance
- Extract reusable views into separate structs
- Use `.animation()` modifiers for smooth transitions

### Example

```swift
// Good
struct TaskRow: View {
    @Bindable var task: TaskItem
    
    var body: some View {
        HStack {
            CompletionToggle(isCompleted: $task.isCompleted)
            TaskTitle(title: task.title)
        }
    }
}

// Avoid
struct TaskRow: View {
    @Bindable var t: TaskItem // unclear naming
    
    var body: some View {
        // 200 lines of inline code...
    }
}
```

## 🧪 Testing

Currently, the project relies on manual testing. When adding features:

1. Test on macOS Sonoma and Sequoia if possible
2. Verify persistence survives app restart
3. Check keyboard shortcuts work correctly
4. Test drag-and-drop functionality
5. Verify accessibility (VoiceOver compatibility)

## 📁 Project Structure

```
TaskScratchpad/
├── Package.swift                 # SwiftPM configuration
├── Sources/
│   ├── TaskScratchpad/
│   │   ├── App.swift             # App entry point
│   │   ├── Models/               # SwiftData models
│   │   │   ├── ExportModels.swift
│   │   │   └── SwiftDataModels.swift
│   │   ├── Store/                # State management
│   │   │   └── TaskStore.swift
│   │   ├── Views/                # SwiftUI views
│   │   │   ├── TaskScratchpadView.swift
│   │   │   ├── TabBarView.swift
│   │   │   ├── TaskBlockView.swift
│   │   │   ├── SubtaskViews.swift
│   │   │   ├── FocusWindowView.swift
│   │   │   └── RichTextEditor.swift
│   │   ├── Components/           # Reusable UI components
│   │   │   ├── ColorPickerPopover.swift
│   │   │   ├── DataDetectingTextEditor.swift
│   │   │   └── VisualEffectView.swift
│   │   ├── Utilities/            # Helpers
│   │   │   ├── HotkeyManager.swift
│   │   │   ├── Theme.swift
│   │   │   ├── DateFormatters.swift
│   │   │   └── ColorExtension.swift
│   │   └── Commands/             # Menu commands
│   │       └── AppCommands.swift
│   └── TaskScratchpadCore/       # Shared utilities
├── scripts/
│   └── create-dmg.sh             # Distribution script
└── docs/
    ├── distribution.md           # How to distribute
    ├── run-local.md              # Development setup
    └── plan/                     # Task plans
```

## 💡 Feature Requests

Before implementing a new feature:

1. Check existing [Issues](../../issues) to avoid duplicates
2. Open an issue to discuss the feature
3. Wait for maintainer feedback before starting work

## 🐛 Bug Reports

When reporting bugs, include:

- macOS version
- Steps to reproduce
- Expected vs actual behavior
- Console logs if applicable

## 📜 Code of Conduct

Be respectful and inclusive. We follow the [Contributor Covenant](https://www.contributor-covenant.org/).

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Questions? Open an issue or reach out to the maintainers. Happy coding! 🎉

