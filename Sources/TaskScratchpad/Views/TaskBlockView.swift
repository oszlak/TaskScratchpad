import SwiftUI
import SwiftData

// MARK: - Task Block (Movable Card)

struct TaskBlock: View {
    @Bindable var task: TaskItem
    let store: TaskStore
    let context: ModelContext
    let onDelete: () -> Void
    let resignInputFocus: () -> Void

    @State private var isHovering: Bool = false
    @State private var showColorPicker: Bool = false

    private var accent: Color { store.color(for: task) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main task row
            HStack(spacing: 10) {
                // Drag handle
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary.opacity(isHovering ? 0.8 : 0.4))
                    .frame(width: 20)

                // Completion toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        task.isCompleted.toggle()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(accent.opacity(0.6), lineWidth: 1.5)
                            .background(Circle().fill(task.isCompleted ? accent.opacity(0.3) : Color.clear))
                        if task.isCompleted {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(accent)
                        }
                    }
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)

                // Title + timestamp + subtask count
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(task.title)
                            .font(.body.weight(.medium))
                            .lineLimit(1)
                            .strikethrough(task.isCompleted, color: .primary.opacity(0.6))
                            .opacity(task.isCompleted ? 0.5 : 1.0)

                        // Subtask progress badge
                        if task.totalSubtasksCount > 0 {
                            Text("\(task.completedSubtasksCount)/\(task.totalSubtasksCount)")
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(accent.opacity(0.15))
                                )
                                .foregroundStyle(accent)
                        }
                    }

                    Text(task.createdAt.relativeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.7))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        task.isExpanded.toggle()
                        resignInputFocus()
                    }
                }

                Spacer()

                // Expand to window button
                Button {
                    openFocusWindow()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open in Focus Mode")
                .opacity(isHovering || task.isExpanded ? 1 : 0)

                // Color picker
                Button {
                    showColorPicker.toggle()
                } label: {
                    Circle()
                        .fill(accent)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showColorPicker, arrowEdge: .bottom) {
                    ColorPaletteView(task: task, isPresented: $showColorPicker)
                }
                .opacity(isHovering || task.isExpanded ? 1 : 0)

                // Delete button
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
            }

            // Expanded content: subtasks + notes
            if task.isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Subtasks section
                    VStack(alignment: .leading, spacing: 4) {
                        // Existing subtasks
                        ForEach(task.sortedSubtasks) { subtask in
                            SubtaskRow(
                                subtask: subtask,
                                accent: accent,
                                onDelete: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        context.delete(subtask)
                                    }
                                }
                            )
                        }

                        // Add subtask field
                        AddSubtaskField(accent: accent) { title in
                            addSubtask(title: title)
                        }
                    }
                    .padding(.leading, 34) // Align with title

                    // Notes area
                    DataDetectingTextEditor(text: $task.notes, placeholder: "Paste links or add context...")
                        .frame(minHeight: 50, maxHeight: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(accent.opacity(0.03))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(accent.opacity(0.1))
                                )
                        )
                        .padding(.leading, 34)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(isHovering ? 0.06 : 0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accent.opacity(isHovering ? 0.25 : 0.1), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isHovering = hovering
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: task.isExpanded)
    }

    private func addSubtask(title: String) {
        let maxOrder = task.subtasks.map(\.sortOrder).max() ?? -1
        let subtask = SubTask(
            title: title,
            sortOrder: maxOrder + 1,
            parent: task
        )
        context.insert(subtask)
    }

    private func openFocusWindow() {
        TaskFocusWindowController.shared.openWindow(for: task)
    }
}

