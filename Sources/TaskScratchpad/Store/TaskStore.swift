import SwiftUI
import SwiftData

// MARK: - Observable Store (macOS 14+)

@Observable
final class TaskStore {
    var isFloating: Bool = false {
        didSet { persistWindowState() }
    }
    var selectedScratchpadID: UUID?

    private let floatingKey = "TaskScratchpad.isFloating"
    private let selectedScratchpadKey = "TaskScratchpad.selectedScratchpad"
    private var nextColorIndex: Int = 0

    // Warm, friendly color palette
    static let palette: [String] = [
        "#E8A87C", // Warm peach
        "#C38D9E", // Dusty rose
        "#41B3A3", // Soft teal
        "#E27D60", // Terracotta
        "#85CDCA", // Mint
        "#D4A574", // Caramel
        "#A8D8EA", // Sky blue
        "#F6D55C"  // Warm yellow
    ]

    init() {
        isFloating = UserDefaults.standard.bool(forKey: floatingKey)
        if let uuidString = UserDefaults.standard.string(forKey: selectedScratchpadKey) {
            selectedScratchpadID = UUID(uuidString: uuidString)
        }
    }

    func selectScratchpad(_ scratchpad: Scratchpad?) {
        selectedScratchpadID = scratchpad?.id
        if let id = scratchpad?.id {
            UserDefaults.standard.set(id.uuidString, forKey: selectedScratchpadKey)
        } else {
            UserDefaults.standard.removeObject(forKey: selectedScratchpadKey)
        }
    }

    func nextColor() -> String {
        let color = Self.palette[nextColorIndex % Self.palette.count]
        nextColorIndex += 1
        return color
    }

    private func persistWindowState() {
        UserDefaults.standard.set(isFloating, forKey: floatingKey)
        updateWindowLevel()
    }

    func updateWindowLevel() {
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.level = self.isFloating ? .floating : .normal
            }
        }
    }

    func color(for task: TaskItem) -> Color {
        Color(hex: task.colorHex) ?? .accentColor
    }

    func color(forHex hex: String) -> Color {
        Color(hex: hex) ?? .accentColor
    }

    // MARK: - Export/Import

    func exportData(scratchpads: [Scratchpad]) -> Data? {
        let exported = ExportedData(
            version: "1.0",
            exportedAt: Date(),
            scratchpads: scratchpads.map { pad in
                ExportedScratchpad(
                    id: pad.id,
                    name: pad.name,
                    colorHex: pad.colorHex,
                    sortOrder: pad.sortOrder,
                    createdAt: pad.createdAt,
                    tasks: pad.tasks.map { task in
                        ExportedTask(
                            id: task.id,
                            title: task.title,
                            notes: task.notes,
                            isCompleted: task.isCompleted,
                            colorHex: task.colorHex,
                            createdAt: task.createdAt,
                            sortOrder: task.sortOrder,
                            subtasks: task.subtasks.map { sub in
                                ExportedSubTask(
                                    id: sub.id,
                                    title: sub.title,
                                    isCompleted: sub.isCompleted,
                                    sortOrder: sub.sortOrder
                                )
                            }
                        )
                    }
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exported)
    }

    func importData(from data: Data, into context: ModelContext) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let exported = try? decoder.decode(ExportedData.self, from: data) else {
            return false
        }

        for exportedPad in exported.scratchpads {
            let pad = Scratchpad(
                id: UUID(), // New ID to avoid conflicts
                name: exportedPad.name,
                colorHex: exportedPad.colorHex,
                sortOrder: exportedPad.sortOrder,
                createdAt: exportedPad.createdAt
            )
            context.insert(pad)

            for exportedTask in exportedPad.tasks {
                let task = TaskItem(
                    id: UUID(),
                    title: exportedTask.title,
                    notes: exportedTask.notes,
                    isCompleted: exportedTask.isCompleted,
                    colorHex: exportedTask.colorHex,
                    createdAt: exportedTask.createdAt,
                    sortOrder: exportedTask.sortOrder,
                    scratchpad: pad
                )
                context.insert(task)

                for exportedSub in exportedTask.subtasks {
                    let subtask = SubTask(
                        id: UUID(),
                        title: exportedSub.title,
                        isCompleted: exportedSub.isCompleted,
                        sortOrder: exportedSub.sortOrder,
                        parent: task
                    )
                    context.insert(subtask)
                }
            }
        }

        return true
    }
}

