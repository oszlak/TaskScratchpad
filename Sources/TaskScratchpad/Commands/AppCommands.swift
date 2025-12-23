import SwiftUI

// MARK: - Notification Names

extension Notification.Name {
    static let focusInput = Notification.Name("TaskScratchpad.focusInput")
    static let toggleVisibility = Notification.Name("TaskScratchpad.toggleVisibility")
    static let clearCompleted = Notification.Name("TaskScratchpad.clearCompleted")
    static let newScratchpad = Notification.Name("TaskScratchpad.newScratchpad")
    static let exportData = Notification.Name("TaskScratchpad.exportData")
    static let importData = Notification.Name("TaskScratchpad.importData")
}

// MARK: - Commands

struct ScratchpadCommands: Commands {
    let store: TaskStore

    var body: some Commands {
        CommandMenu("Scratchpad") {
            Button("New Task") {
                NotificationCenter.default.post(name: .focusInput, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("New Tab") {
                NotificationCenter.default.post(name: .newScratchpad, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command])

            Divider()

            Button("Clear Completed") {
                NotificationCenter.default.post(name: .clearCompleted, object: nil)
            }
            .keyboardShortcut("k", modifiers: [.command])

            Divider()

            Button("Export All Data...") {
                NotificationCenter.default.post(name: .exportData, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Button("Import Data...") {
                NotificationCenter.default.post(name: .importData, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])

            Divider()

            Toggle("Float on Top", isOn: Bindable(store).isFloating)
        }
    }
}

