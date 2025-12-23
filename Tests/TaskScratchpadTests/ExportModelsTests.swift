import Testing
import Foundation

// Re-define the export models for testing (since they're in executable target)
// In a production setup, these would be in a shared library

struct TestExportedSubTask: Codable, Equatable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let sortOrder: Int
}

struct TestExportedTask: Codable, Equatable {
    let id: UUID
    let title: String
    let notes: String
    let isCompleted: Bool
    let colorHex: String
    let createdAt: Date
    let sortOrder: Int
    let subtasks: [TestExportedSubTask]
}

struct TestExportedScratchpad: Codable, Equatable {
    let id: UUID
    let name: String
    let colorHex: String
    let sortOrder: Int
    let createdAt: Date
    let tasks: [TestExportedTask]
}

struct TestExportedData: Codable, Equatable {
    let version: String
    let exportedAt: Date
    let scratchpads: [TestExportedScratchpad]
}

@Suite("Export Models")
struct ExportModelsTests {

    @Test("ExportedSubTask encodes and decodes correctly")
    func subtaskCodable() throws {
        let subtask = TestExportedSubTask(
            id: UUID(),
            title: "Test Subtask",
            isCompleted: true,
            sortOrder: 1
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(subtask)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TestExportedSubTask.self, from: data)

        #expect(decoded == subtask)
    }

    @Test("ExportedTask encodes and decodes correctly")
    func taskCodable() throws {
        let task = TestExportedTask(
            id: UUID(),
            title: "Test Task",
            notes: "Some notes",
            isCompleted: false,
            colorHex: "#E8A87C",
            createdAt: Date(),
            sortOrder: 0,
            subtasks: [
                TestExportedSubTask(id: UUID(), title: "Sub 1", isCompleted: false, sortOrder: 0),
                TestExportedSubTask(id: UUID(), title: "Sub 2", isCompleted: true, sortOrder: 1)
            ]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestExportedTask.self, from: data)

        #expect(decoded.title == task.title)
        #expect(decoded.notes == task.notes)
        #expect(decoded.isCompleted == task.isCompleted)
        #expect(decoded.colorHex == task.colorHex)
        #expect(decoded.subtasks.count == 2)
    }

    @Test("ExportedScratchpad encodes and decodes correctly")
    func scratchpadCodable() throws {
        let scratchpad = TestExportedScratchpad(
            id: UUID(),
            name: "My Tasks",
            colorHex: "#41B3A3",
            sortOrder: 0,
            createdAt: Date(),
            tasks: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(scratchpad)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestExportedScratchpad.self, from: data)

        #expect(decoded.name == scratchpad.name)
        #expect(decoded.colorHex == scratchpad.colorHex)
    }

    @Test("ExportedData full structure encodes and decodes")
    func fullDataCodable() throws {
        let subtask = TestExportedSubTask(
            id: UUID(),
            title: "Subtask",
            isCompleted: false,
            sortOrder: 0
        )

        let task = TestExportedTask(
            id: UUID(),
            title: "Task",
            notes: "Notes",
            isCompleted: false,
            colorHex: "#E8A87C",
            createdAt: Date(),
            sortOrder: 0,
            subtasks: [subtask]
        )

        let scratchpad = TestExportedScratchpad(
            id: UUID(),
            name: "Scratchpad",
            colorHex: "#41B3A3",
            sortOrder: 0,
            createdAt: Date(),
            tasks: [task]
        )

        let exportData = TestExportedData(
            version: "1.0",
            exportedAt: Date(),
            scratchpads: [scratchpad]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestExportedData.self, from: data)

        #expect(decoded.version == "1.0")
        #expect(decoded.scratchpads.count == 1)
        #expect(decoded.scratchpads[0].tasks.count == 1)
        #expect(decoded.scratchpads[0].tasks[0].subtasks.count == 1)
    }

    @Test("JSON output is valid and readable")
    func jsonOutput() throws {
        let exportData = TestExportedData(
            version: "1.0",
            exportedAt: Date(),
            scratchpads: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)

        let jsonString = String(data: data, encoding: .utf8)
        #expect(jsonString != nil)
        #expect(jsonString!.contains("\"version\""))
        #expect(jsonString!.contains("\"scratchpads\""))
        #expect(jsonString!.contains("\"exportedAt\""))
    }

    @Test("Empty subtasks array encodes correctly")
    func emptySubtasks() throws {
        let task = TestExportedTask(
            id: UUID(),
            title: "No Subtasks",
            notes: "",
            isCompleted: false,
            colorHex: "#E8A87C",
            createdAt: Date(),
            sortOrder: 0,
            subtasks: []
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestExportedTask.self, from: data)

        #expect(decoded.subtasks.isEmpty)
    }

    @Test("Color hex values are preserved")
    func colorHexPreserved() throws {
        let hexColors = ["#E8A87C", "#C38D9E", "#41B3A3", "#000000", "#FFFFFF"]

        for hex in hexColors {
            let scratchpad = TestExportedScratchpad(
                id: UUID(),
                name: "Test",
                colorHex: hex,
                sortOrder: 0,
                createdAt: Date(),
                tasks: []
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(scratchpad)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(TestExportedScratchpad.self, from: data)

            #expect(decoded.colorHex == hex, "Color hex \(hex) should be preserved")
        }
    }

    @Test("Sort order is preserved across encode/decode")
    func sortOrderPreserved() throws {
        let subtasks = (0..<5).map { index in
            TestExportedSubTask(
                id: UUID(),
                title: "Subtask \(index)",
                isCompleted: false,
                sortOrder: index
            )
        }

        let task = TestExportedTask(
            id: UUID(),
            title: "Task",
            notes: "",
            isCompleted: false,
            colorHex: "#E8A87C",
            createdAt: Date(),
            sortOrder: 0,
            subtasks: subtasks
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(task)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TestExportedTask.self, from: data)

        for (index, subtask) in decoded.subtasks.enumerated() {
            #expect(subtask.sortOrder == index, "Sort order should be preserved")
        }
    }
}

