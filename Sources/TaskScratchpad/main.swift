import SwiftUI
import SwiftData
import AppKit
import Combine
import Carbon.HIToolbox

// MARK: - SwiftData Models

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
    var notes: String
    var isCompleted: Bool
    var isExpanded: Bool
    var colorHex: String
    var createdAt: Date
    var sortOrder: Int
    @Relationship(deleteRule: .cascade, inverse: \SubTask.parent)
    var subtasks: [SubTask]

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        isExpanded: Bool = true,
        colorHex: String = "#6EA8FE",
        createdAt: Date = Date(),
        sortOrder: Int = 0,
        subtasks: [SubTask] = []
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.isExpanded = isExpanded
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.sortOrder = sortOrder
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

// MARK: - Observable Store (macOS 14+)

@Observable
final class TaskStore {
    var isFloating: Bool = false {
        didSet { persistWindowState() }
    }

    private let floatingKey = "TaskScratchpad.isFloating"
    private var nextColorIndex: Int = 0

    static let palette: [String] = [
        "#6EA8FE", "#8F7CFF", "#F39C12", "#FF6F61",
        "#1ABC9C", "#E67E22", "#5DADE2", "#AF7AC5"
    ]

    init() {
        isFloating = UserDefaults.standard.bool(forKey: floatingKey)
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
}

// MARK: - Global Hotkey Manager

final class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    private var eventMonitor: Any?

    func register(onTrigger: @escaping () -> Void) {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                DispatchQueue.main.async {
                    onTrigger()
                }
            }
        }
    }

    func unregister() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

// MARK: - Visual Effect Wrapper

struct BlurBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Data Detecting Text Editor with Placeholder

struct DataDetectingTextEditor: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = "Paste links or add context..."

    func makeNSView(context: Context) -> NSScrollView {
        let textView = PlaceholderTextView()
        textView.placeholderString = placeholder
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.textContainer?.widthTracksTextView = true
        textView.font = .systemFont(ofSize: 13)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isAutomaticLinkDetectionEnabled = true
        textView.isAutomaticDataDetectionEnabled = true
        textView.delegate = context.coordinator

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? PlaceholderTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.placeholderString = placeholder
        textView.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: DataDetectingTextEditor

        init(_ parent: DataDetectingTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

final class PlaceholderTextView: NSTextView {
    var placeholderString: String = "" {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if string.isEmpty && !placeholderString.isEmpty {
            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.placeholderTextColor,
                .font: font ?? NSFont.systemFont(ofSize: 13)
            ]
            let inset = textContainerInset
            let rect = NSRect(x: inset.width + 5, y: inset.height, width: bounds.width - inset.width * 2, height: bounds.height)
            placeholderString.draw(in: rect, withAttributes: attrs)
        }
    }

    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        needsDisplay = true
        return super.resignFirstResponder()
    }
}

// MARK: - Relative Date Formatter

extension Date {
    var relativeString: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        if interval < 604800 { return "\(Int(interval / 86400))d ago" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Color Picker Popover

struct ColorPaletteView: View {
    @Bindable var task: TaskItem
    @Binding var isPresented: Bool

    private let colors = TaskStore.palette

    var body: some View {
        VStack(spacing: 8) {
            Text("Pick a color")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 28))], spacing: 8) {
                ForEach(colors, id: \.self) { hex in
                    Button {
                        task.colorHex = hex
                        isPresented = false
                    } label: {
                        Circle()
                            .fill(Color(hex: hex) ?? .accentColor)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(task.colorHex == hex ? Color.primary : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(width: 160)
    }
}

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
                .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)

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
        .contentShape(Rectangle())
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
}

// MARK: - Commands

extension Notification.Name {
    static let focusInput = Notification.Name("TaskScratchpad.focusInput")
    static let toggleVisibility = Notification.Name("TaskScratchpad.toggleVisibility")
    static let clearCompleted = Notification.Name("TaskScratchpad.clearCompleted")
}

struct ScratchpadCommands: Commands {
    let store: TaskStore

    var body: some Commands {
        CommandMenu("Scratchpad") {
            Button("New Task") {
                NotificationCenter.default.post(name: .focusInput, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("Clear Completed") {
                NotificationCenter.default.post(name: .clearCompleted, object: nil)
            }
            .keyboardShortcut("k", modifiers: [.command])

            Divider()

            Toggle("Float on Top", isOn: Bindable(store).isFloating)
        }
    }
}

// MARK: - Main Content

struct TaskScratchpadView: View {
    @Environment(\.modelContext) private var context
    @Query private var allTasks: [TaskItem]

    var store: TaskStore
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    init(store: TaskStore) {
        self.store = store
        _allTasks = Query()
    }

    // Sorted tasks: active first by sortOrder, then completed
    private var sortedTasks: [TaskItem] {
        let active = allTasks.filter { !$0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        let completed = allTasks.filter { $0.isCompleted }.sorted { $0.sortOrder < $1.sortOrder }
        return active + completed
    }

    var body: some View {
        ZStack {
            BlurBackground().ignoresSafeArea()

            VStack(spacing: 12) {
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
            .padding(16)
        }
        .onAppear {
            store.updateWindowLevel()
            normalizeSortOrders()
        }
        .frame(minWidth: 420, minHeight: 520)
        .preferredColorScheme(nil)
        .onReceive(NotificationCenter.default.publisher(for: .clearCompleted)) { _ in
            clearCompleted()
        }
        .onKeyPress(.escape) {
            isInputFocused = true
            return .handled
        }
    }

    private func addTask() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let minOrder = allTasks.map(\.sortOrder).min() ?? 0
        let newTask = TaskItem(
            title: trimmed,
            isExpanded: true,
            colorHex: store.nextColor(),
            sortOrder: minOrder - 1
        )
        context.insert(newTask)
        inputText = ""
        isInputFocused = true
    }

    private func deleteTask(_ task: TaskItem) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            context.delete(task)
        }
    }

    private func clearCompleted() {
        for task in allTasks where task.isCompleted {
            context.delete(task)
        }
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var tasks = sortedTasks
        tasks.move(fromOffsets: source, toOffset: destination)

        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
    }

    private func normalizeSortOrders() {
        let sorted = allTasks.sorted { $0.sortOrder < $1.sortOrder }
        for (index, task) in sorted.enumerated() {
            if task.sortOrder != index {
                task.sortOrder = index
            }
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

// MARK: - App Entry

@main
struct TaskScratchpadApp: App {
    @State private var store = TaskStore()
    @State private var isWindowVisible = true

    var body: some Scene {
        WindowGroup {
            TaskScratchpadView(store: store)
                .modelContainer(for: [TaskItem.self, SubTask.self])
                .onAppear {
                    store.updateWindowLevel()
                    setupGlobalHotkey()
                }
                .onReceive(NotificationCenter.default.publisher(for: .toggleVisibility)) { _ in
                    toggleWindowVisibility()
                }
        }
        .windowResizability(.contentSize)
        .commands {
            ScratchpadCommands(store: store)
        }
    }

    private func setupGlobalHotkey() {
        GlobalHotkeyManager.shared.register {
            NotificationCenter.default.post(name: .toggleVisibility, object: nil)
        }
    }

    private func toggleWindowVisibility() {
        guard let window = NSApp.windows.first else { return }
        if window.isVisible {
            window.orderOut(nil)
            isWindowVisible = false
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            isWindowVisible = true
            NotificationCenter.default.post(name: .focusInput, object: nil)
        }
    }
}

// MARK: - Color Helper

extension Color {
    init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        guard hexString.count == 6,
              let rgb = Int(hexString, radix: 16) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}
