import Foundation

// MARK: - Export/Import Models (Codable)

struct ExportedSubTask: Codable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let sortOrder: Int
}

struct ExportedTask: Codable {
    let id: UUID
    let title: String
    let notes: String
    let isCompleted: Bool
    let colorHex: String
    let createdAt: Date
    let sortOrder: Int
    let subtasks: [ExportedSubTask]
}

struct ExportedScratchpad: Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let sortOrder: Int
    let createdAt: Date
    let tasks: [ExportedTask]
}

struct ExportedData: Codable {
    let version: String
    let exportedAt: Date
    let scratchpads: [ExportedScratchpad]
}

