import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class Scratchpad {
    var id: UUID
    var name: String
    var colorHex: String
    var sortOrder: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \TaskItem.scratchpad)
    var tasks: [TaskItem]

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#6EA8FE",
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        tasks: [TaskItem] = []
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.tasks = tasks
    }

    var sortedTasks: [TaskItem] {
        let active = tasks.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        let completed = tasks.filter { $0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        return active + completed
    }

    var taskCount: Int { tasks.count }
    var completedCount: Int { tasks.filter(\.isCompleted).count }
}

@Model
final class SubTask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int
    var parent: TaskItem?

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        sortOrder: Int = 0,
        parent: TaskItem? = nil
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.parent = parent
    }
}

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String              // Plain text - shown in task row (3-4 lines context)
    var focusNotes: String = ""    // Rich text (RTF base64) - shown in Focus Mode
    var isCompleted: Bool
    var isExpanded: Bool
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int
    var scratchpad: Scratchpad?
    @Relationship(deleteRule: .cascade, inverse: \SubTask.parent)
    var subtasks: [SubTask]

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        focusNotes: String = "",
        isCompleted: Bool = false,
        isExpanded: Bool = true,
        colorHex: String = "#6EA8FE",
        createdAt: Date = Date(),
        sortOrder: Int = 0,
        scratchpad: Scratchpad? = nil,
        subtasks: [SubTask] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.focusNotes = focusNotes
        self.isCompleted = isCompleted
        self.isExpanded = isExpanded
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.scratchpad = scratchpad
        self.subtasks = subtasks
    }

    var sortedSubtasks: [SubTask] {
        subtasks.sorted { $0.sortOrder < $1.sortOrder }
    }

    var completedSubtasksCount: Int {
        subtasks.filter(\.isCompleted).count
    }

    var totalSubtasksCount: Int {
        subtasks.count
    }
}

