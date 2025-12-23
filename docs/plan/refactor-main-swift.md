# Refactor: Split main.swift into Modules

## User Story
Split the monolithic 2100+ line `main.swift` into logical, maintainable modules following Swift best practices.

## Current State
`main.swift` contains 19 logical sections (identified by `// MARK:` comments):
1. Export/Import Models (Codable)
2. SwiftData Models
3. Observable Store
4. Global Hotkey Manager
5. Visual Effect Wrapper
6. UI Theme
7. Data Detecting Text Editor
8. Relative Date Formatter
9. Color Picker Popover
10. Subtask Row
11. Add Subtask Field
12. Task Block (Card)
13. Focus Window
14. Rich Text Editor (WYSIWYG)
15. Tab Bar
16. Commands
17. Main Content
18. App Entry
19. Color Helper

## Proposed Structure
```
Sources/TaskScratchpad/
├── main.swift                    # App entry only (~50 lines)
├── Models/
│   ├── SwiftDataModels.swift     # Scratchpad, TaskItem, SubTask
│   └── ExportModels.swift        # Codable export/import structs
├── Store/
│   └── ScratchpadStore.swift     # Observable store
├── Views/
│   ├── TaskScratchpadView.swift  # Main content view
│   ├── TabBarView.swift          # Tab bar
│   ├── TaskBlockView.swift       # Task card
│   ├── SubtaskViews.swift        # SubtaskRow, AddSubtaskField
│   ├── FocusWindowView.swift     # Focus mode
│   └── RichTextEditor.swift      # WYSIWYG editor
├── Components/
│   ├── ColorPickerPopover.swift
│   ├── DataDetectingTextEditor.swift
│   └── VisualEffectView.swift
├── Utilities/
│   ├── HotkeyManager.swift
│   ├── Theme.swift
│   └── DateFormatters.swift
└── Commands/
    └── AppCommands.swift
```

## Implementation Steps

### Step 1: Create Models/ ✅
- [x] Create `ExportModels.swift` - move ExportedSubTask, ExportedTask, ExportedScratchpad, ExportedData
- [x] Create `SwiftDataModels.swift` - move Scratchpad, TaskItem, SubTask @Model classes
- **Success Criteria:** Models compile independently, no circular dependencies

### Step 2: Create Store/ ✅
- [x] Create `TaskStore.swift` - move TaskStore observable class
- **Success Criteria:** Store compiles, imports Models correctly

### Step 3: Create Utilities/ ✅
- [x] Create `HotkeyManager.swift` - move GlobalHotkeyManager
- [x] Create `Theme.swift` - move AppTheme
- [x] Create `DateFormatters.swift` - move relativeDateFormatter
- [x] Create `ColorExtension.swift` - move Color hex initializer
- **Success Criteria:** Utilities compile independently

### Step 4: Create Components/ ✅
- [x] Create `VisualEffectView.swift` - move BlurBackground
- [x] Create `ColorPickerPopover.swift` - move ColorPaletteView
- [x] Create `DataDetectingTextEditor.swift` - move DataDetectingTextEditor + PlaceholderTextView
- **Success Criteria:** Components compile with proper imports

### Step 5: Create Views/ ✅
- [x] Create `SubtaskViews.swift` - move SubtaskRow, AddSubtaskField, FocusSubtaskRow
- [x] Create `TaskBlockView.swift` - move TaskBlock
- [x] Create `FocusWindowView.swift` - move TaskFocusWindowController, TaskFocusView
- [x] Create `RichTextEditor.swift` - move RichTextEditor + all coordinator/controller classes
- [x] Create `TabBarView.swift` - move ScratchpadTab, ScratchpadTabBar
- [x] Create `TaskScratchpadView.swift` - move main content view
- **Success Criteria:** All views render correctly

### Step 6: Create Commands/ ✅
- [x] Create `AppCommands.swift` - move Notification.Name extensions + ScratchpadCommands
- **Success Criteria:** Menu commands work

### Step 7: Slim down main.swift → App.swift ✅
- [x] Renamed to `App.swift` (main.swift is special in Swift)
- [x] Keep only: imports, @main App struct, scene configuration
- [x] Verify all imports are correct
- **Success Criteria:** `swift build` passes, `swift run` works

### Step 8: Verification ✅
- [x] Run `swift build` - no errors
- [x] Run `swift run` - app launches correctly

## Checkpoints
- [x] **Checkpoint 1:** After Step 2 - Models and Store compile
- [x] **Checkpoint 2:** After Step 5 - All views compile
- [x] **Checkpoint 3:** After Step 8 - Full verification

## Completion Status: ✅ DONE

## Notes
- Keep `internal` access level (Swift default) for now
- Consider `public` for `TaskScratchpadCore` module items later
- Watch for circular dependencies between Views and Store

