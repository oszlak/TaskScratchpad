## [0.0.2](https://github.com/oszlak/TaskScratchpad/compare/v0.0.1...v0.0.2) (2025-12-23)


### Bug Fixes

* correct version extraction in release-tag workflow ([8d32db3](https://github.com/oszlak/TaskScratchpad/commit/8d32db393d908b5e002cdec9a6e523b22c942e26))

# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/).

## [0.0.1] - 2025-12-23

### Added
- Initial release of Task Scratchpad
- Multiple scratchpads with tabs (Cmd+T to add)
- Task management with drag-and-drop reordering
- Subtasks with progress tracking
- Focus mode window for detailed notes with rich text support
- Import/export to JSON (Cmd+Shift+E/I)
- Global hotkey (Option+Space) to show/hide
- Color-coded tasks and scratchpads
- App icon (warm peach notepad with teal checkmark)
- Rename tabs (pencil icon or double-click)
- Empty state with friendly messaging

### Technical
- SwiftUI + SwiftData for modern macOS 14+ support
- Modular codebase with clear separation of concerns
- XCUITest infrastructure for UI testing
- GitHub Actions CI/CD with code coverage
