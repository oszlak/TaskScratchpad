import SwiftUI
import SwiftData

// MARK: - Tab Bar

struct ScratchpadTab: View {
    @Bindable var scratchpad: Scratchpad
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var isEditing = false
    @State private var editedName: String = ""

    private var accent: Color {
        Color(hex: scratchpad.colorHex) ?? .accentColor
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)

            if isEditing {
                TextField("Name", text: $editedName)
                    .textFieldStyle(.plain)
                    .font(.caption.weight(.medium))
                    .frame(width: 60)
                    .onSubmit {
                        scratchpad.name = editedName
                        isEditing = false
                    }
                    .onExitCommand {
                        isEditing = false
                    }
            } else {
                Text(scratchpad.name)
                    .font(.caption.weight(isSelected ? .semibold : .medium))
                    .lineLimit(1)
            }

            if scratchpad.taskCount > 0 {
                Text("\(scratchpad.taskCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if isHovering && !isEditing {
                // Rename button
                Button {
                    editedName = scratchpad.name
                    isEditing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Rename")

                // Delete button
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Delete")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? accent.opacity(0.15) : Color.primary.opacity(isHovering ? 0.05 : 0))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? accent.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onTapGesture(count: 2) {
            editedName = scratchpad.name
            isEditing = true
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

struct ScratchpadTabBar: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Scratchpad.sortOrder) private var scratchpads: [Scratchpad]
    @Bindable var store: TaskStore

    @State private var showColorPicker = false
    @State private var newPadColor = "#E8A87C"

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(scratchpads) { pad in
                    ScratchpadTab(
                        scratchpad: pad,
                        isSelected: store.selectedScratchpadID == pad.id,
                        onSelect: { store.selectScratchpad(pad) },
                        onDelete: { deleteScratchpad(pad) }
                    )
                }

                // Add new scratchpad button
                Button {
                    addScratchpad()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                        )
                }
                .buttonStyle(.plain)
                .help("Add new scratchpad")
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 36)
        .onAppear {
            ensureDefaultScratchpad()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newScratchpad)) { _ in
            addScratchpad()
        }
    }

    private func ensureDefaultScratchpad() {
        if scratchpads.isEmpty {
            let defaultPad = Scratchpad(name: "My Tasks", colorHex: "#E8A87C", sortOrder: 0)
            context.insert(defaultPad)
            store.selectScratchpad(defaultPad)
        } else if store.selectedScratchpadID == nil {
            store.selectScratchpad(scratchpads.first)
        } else if !scratchpads.contains(where: { $0.id == store.selectedScratchpadID }) {
            store.selectScratchpad(scratchpads.first)
        }
    }

    private func addScratchpad() {
        let maxOrder = scratchpads.map(\.sortOrder).max() ?? -1
        let newPad = Scratchpad(
            name: "Untitled",
            colorHex: store.nextColor(),
            sortOrder: maxOrder + 1
        )
        context.insert(newPad)
        store.selectScratchpad(newPad)
    }

    private func deleteScratchpad(_ pad: Scratchpad) {
        guard scratchpads.count > 1 else { return } // Keep at least one

        let wasSelected = store.selectedScratchpadID == pad.id
        context.delete(pad)

        if wasSelected {
            store.selectScratchpad(scratchpads.first { $0.id != pad.id })
        }
    }
}

