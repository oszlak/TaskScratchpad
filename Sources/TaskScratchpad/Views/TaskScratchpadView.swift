import SwiftUI
import SwiftData
import AppKit

// MARK: - Main Content

struct TaskScratchpadView: View {
    @Environment(\.modelContext) private var context
    @Query private var allScratchpads: [Scratchpad]

    @Bindable var store: TaskStore
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    init(store: TaskStore) {
        self._store = Bindable(wrappedValue: store)
        _allScratchpads = Query(sort: \Scratchpad.sortOrder)
    }

    private var selectedScratchpad: Scratchpad? {
        allScratchpads.first { $0.id == store.selectedScratchpadID }
    }

    private var sortedTasks: [TaskItem] {
        selectedScratchpad?.sortedTasks ?? []
    }

    var body: some View {
        ZStack {
            BlurBackground().ignoresSafeArea()

            VStack(spacing: 12) {
                // Tab bar
                ScratchpadTabBar(store: store)

                // Quick-add field
                TextField("Quick add a task and hit Return…", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primary.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1))
                            )
                    )
                    .focused($isInputFocused)
                    .onSubmit { addTask() }
                    .onAppear {
                        activateWindow()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isInputFocused = true
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .focusInput)) { _ in
                        activateWindow()
                        DispatchQueue.main.async { isInputFocused = true }
                    }

                // Task list with native reordering
                if sortedTasks.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(AppTheme.emptyStateColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(AppTheme.emptyStateColor.opacity(0.6))
                        }

                        VStack(spacing: 6) {
                            Text("Ready to be productive?")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(.primary.opacity(0.8))
                            Text("Type above and press Return to add your first task")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                } else {
                    List {
                        ForEach(sortedTasks) { task in
                            TaskBlock(
                                task: task,
                                store: store,
                                context: context,
                                onDelete: { deleteTask(task) },
                                resignInputFocus: { isInputFocused = false }
                            )
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                            .listRowBackground(Color.clear)
                        }
                        .onMove(perform: moveItems)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(16)
        }
        .onAppear {
            store.updateWindowLevel()
        }
        .frame(minWidth: 420, minHeight: 520)
        .preferredColorScheme(nil)
        .onReceive(NotificationCenter.default.publisher(for: .clearCompleted)) { _ in
            clearCompleted()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportData)) { _ in
            exportAllData()
        }
        .onReceive(NotificationCenter.default.publisher(for: .importData)) { _ in
            importDataFromFile()
        }
        .onKeyPress(.escape) {
            isInputFocused = true
            return .handled
        }
    }

    private func exportAllData() {
        guard let data = store.exportData(scratchpads: allScratchpads) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "TaskScratchpad-Backup.json"
        panel.title = "Export Tasks"
        panel.message = "Choose where to save your backup"

        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }

    private func importDataFromFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Import Tasks"
        panel.message = "Select a backup file to import"

        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url) {
                let success = store.importData(from: data, into: context)
                if success {
                    // Select the first imported scratchpad
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let first = allScratchpads.first {
                            store.selectScratchpad(first)
                        }
                    }
                }
            }
        }
    }

    private func addTask() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let pad = selectedScratchpad else {
            print("DEBUG: No scratchpad selected!")
            return
        }

        let minOrder = pad.tasks.map(\.sortOrder).min() ?? 0
        let newTask = TaskItem(
            title: trimmed,
            isExpanded: true,
            colorHex: store.nextColor(),
            sortOrder: minOrder - 1,
            scratchpad: pad
        )
        context.insert(newTask)
        pad.tasks.append(newTask) // Ensure relationship is set from both sides
        inputText = ""
        isInputFocused = true
    }

    private func deleteTask(_ task: TaskItem) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            context.delete(task)
        }
    }

    private func clearCompleted() {
        guard let pad = selectedScratchpad else { return }
        for task in pad.tasks where task.isCompleted {
            context.delete(task)
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        guard let pad = selectedScratchpad else { return }
        var tasks = pad.sortedTasks
        tasks.move(fromOffsets: source, toOffset: destination)

        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
    }

    private func activateWindow() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}

