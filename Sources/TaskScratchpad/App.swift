import SwiftUI
import SwiftData
import AppKit

// MARK: - App Entry

@main
struct TaskScratchpadApp: App {
    @State private var store = TaskStore()
    @State private var isWindowVisible = true

    var body: some Scene {
        WindowGroup {
            TaskScratchpadView(store: store)
                .modelContainer(for: [Scratchpad.self, TaskItem.self, SubTask.self])
                .onAppear {
                    store.updateWindowLevel()
                    setupGlobalHotkey()
                }
                .onReceive(NotificationCenter.default.publisher(for: .toggleVisibility)) { _ in
                    toggleWindowVisibility()
                }
        }
        .windowResizability(.contentSize)
        .commands {
            ScratchpadCommands(store: store)
        }
    }

    private func setupGlobalHotkey() {
        GlobalHotkeyManager.shared.register {
            NotificationCenter.default.post(name: .toggleVisibility, object: nil)
        }
    }

    private func toggleWindowVisibility() {
        guard let window = NSApp.windows.first else { return }
        if window.isVisible {
            window.orderOut(nil)
            isWindowVisible = false
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isWindowVisible = true
            NotificationCenter.default.post(name: .focusInput, object: nil)
        }
    }
}
