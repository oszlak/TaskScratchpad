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

### Branch Naming

- `feature/description` — New features
- `fix/description` — Bug fixes
- `docs/description` — Documentation updates
- `refactor/description` — Code refactoring

### Commit Messages

Use clear, descriptive commit messages:

```
feat: add drag-and-drop reordering for tasks
fix: resolve keyboard focus issue in notes field
docs: update installation instructions
refactor: simplify TaskStore state management
```

### Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Test thoroughly on macOS
4. Update documentation if needed
5. Submit a PR with a clear description

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
│   └── TaskScratchpad/
│       └── main.swift            # Main application (single file)
├── scripts/
│   └── create-dmg.sh             # Distribution script
└── docs/
    ├── distribution.md           # How to distribute
    └── run-local.md              # Development setup
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

