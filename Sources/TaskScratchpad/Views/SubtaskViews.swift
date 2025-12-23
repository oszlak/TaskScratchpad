import SwiftUI

// MARK: - Subtask Row

struct SubtaskRow: View {
    @Bindable var subtask: SubTask
    let accent: Color
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 8) {
            // Completion toggle
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    subtask.isCompleted.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(accent.opacity(0.5), lineWidth: 1.2)
                        .background(Circle().fill(subtask.isCompleted ? accent.opacity(0.2) : Color.clear))
                    if subtask.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(accent)
                    }
                }
                .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderless)
            .contentShape(Circle().inset(by: -8))
            .frame(width: 28, height: 28)

            // Title
            Text(subtask.title)
                .font(.subheadline)
                .lineLimit(1)
                .strikethrough(subtask.isCompleted, color: .primary.opacity(0.5))
                .opacity(subtask.isCompleted ? 0.5 : 0.9)

            Spacer()

            // Delete
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(isHovering ? 0.04 : 0))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Add Subtask Field

struct AddSubtaskField: View {
    let accent: Color
    let onAdd: (String) -> Void

    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 14))
                .foregroundStyle(accent.opacity(0.6))

            TextField("Add subtask...", text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .focused($isFocused)
                .onSubmit {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        onAdd(trimmed)
                        text = ""
                    }
                }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(accent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(accent.opacity(0.1))
                )
        )
    }
}

// MARK: - Focus Subtask Row (used in Focus Window)

struct FocusSubtaskRow: View {
    @Bindable var subtask: SubTask
    let accent: Color

    var body: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    subtask.isCompleted.toggle()
                }
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(accent.opacity(0.5), lineWidth: 1.5)
                        .background(Circle().fill(subtask.isCompleted ? accent.opacity(0.2) : Color.clear))
                    if subtask.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(accent)
                    }
                }
                .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            Text(subtask.title)
                .font(.body)
                .strikethrough(subtask.isCompleted)
                .opacity(subtask.isCompleted ? 0.5 : 1)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

