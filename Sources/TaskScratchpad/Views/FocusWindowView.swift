import SwiftUI
import AppKit

// MARK: - Focus Window Controller

final class TaskFocusWindowController {
    static let shared = TaskFocusWindowController()
    private var windows: [UUID: NSWindow] = [:]

    func openWindow(for task: TaskItem) {
        // If window already exists, bring it to front
        if let existingWindow = windows[task.id] {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = TaskFocusView(task: task, onClose: { [weak self] in
            self?.closeWindow(for: task.id)
        })

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = task.title
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        windows[task.id] = window

        // Clean up when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.windows.removeValue(forKey: task.id)
        }
    }

    func closeWindow(for taskId: UUID) {
        windows[taskId]?.close()
        windows.removeValue(forKey: taskId)
    }
}

// MARK: - Focus View

struct TaskFocusView: View {
    @Bindable var task: TaskItem
    let onClose: () -> Void

    @State private var isEditing = false
    @State private var editedTitle: String = ""

    private var accent: Color {
        Color(hex: task.colorHex) ?? Color(hex: "#E8A87C")!
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Completion toggle
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        task.isCompleted.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(accent.opacity(0.6), lineWidth: 2)
                            .background(Circle().fill(task.isCompleted ? accent.opacity(0.3) : Color.clear))
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(accent)
                        }
                    }
                    .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)

                // Title (editable)
                if isEditing {
                    TextField("Task title", text: $editedTitle)
                        .textFieldStyle(.plain)
                        .font(.title2.weight(.semibold))
                        .onSubmit {
                            task.title = editedTitle
                            isEditing = false
                        }
                        .onExitCommand {
                            isEditing = false
                        }
                } else {
                    Text(task.title)
                        .font(.title2.weight(.semibold))
                        .strikethrough(task.isCompleted)
                        .opacity(task.isCompleted ? 0.5 : 1)
                        .onTapGesture(count: 2) {
                            editedTitle = task.title
                            isEditing = true
                        }
                }

                Spacer()

                // Created date
                Text(task.createdAt.relativeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(accent.opacity(0.08))

            Divider()

            // Main content area
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quick context (shown in task row)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Quick Context", systemImage: "text.bubble")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("This appears in the task list (3-4 lines)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        TextEditor(text: $task.notes)
                            .font(.body)
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .frame(height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.primary.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(accent.opacity(0.15))
                                    )
                            )
                    }

                    Divider()

                    // Full notes section with rich text
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Full Notes & Thoughts", systemImage: "doc.richtext")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("Rich text editor - format text, add links, etc.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        RichTextEditor(text: $task.focusNotes, accent: accent)
                            .frame(minHeight: 280)
                    }

                    // Subtasks section
                    if !task.subtasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Subtasks (\(task.completedSubtasksCount)/\(task.totalSubtasksCount))", systemImage: "checklist")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            VStack(spacing: 6) {
                                ForEach(task.sortedSubtasks) { subtask in
                                    FocusSubtaskRow(subtask: subtask, accent: accent)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.primary.opacity(0.03))
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

