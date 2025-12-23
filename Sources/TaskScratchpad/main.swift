import SwiftUI
import SwiftData
import AppKit
import Combine
import Carbon.HIToolbox
import UniformTypeIdentifiers

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
    var notes: String
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
        view.material = .hudWindow // Warmer, softer material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - UI Theme

enum AppTheme {
    static let cardBackground = Color.primary.opacity(0.03)
    static let cardBackgroundHover = Color.primary.opacity(0.06)
    static let cardBorder = Color.primary.opacity(0.08)
    static let inputBackground = Color(hex: "#FDF6E3")?.opacity(0.3) ?? Color.primary.opacity(0.05)
    static let emptyStateColor = Color(hex: "#D4A574") ?? .secondary
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

// MARK: - Focus Window (Full Notes Editor)

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

// MARK: - Rich Text Toolbar (Office/Docs Style)

struct ToolbarButton: View {
    let icon: String
    let label: String?
    let help: String
    let isActive: Bool
    let action: () -> Void

    init(icon: String, label: String? = nil, help: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.help = help
        self.isActive = isActive
        self.action = action
    }

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                if let label = label {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                }
            }
            .foregroundStyle(isActive ? Color.accentColor : (isHovering ? .primary : .secondary))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Color.accentColor.opacity(0.15) : (isHovering ? Color.primary.opacity(0.08) : Color.clear))
            )
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

struct ToolbarDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 1, height: 24)
            .padding(.horizontal, 8)
    }
}

struct HeadingPicker: View {
    @Binding var text: String
    @State private var isExpanded = false

    var body: some View {
        Menu {
            Button("Normal Text") { }
            Divider()
            Button("Heading 1") { insertHeading("# ") }
            Button("Heading 2") { insertHeading("## ") }
            Button("Heading 3") { insertHeading("### ") }
        } label: {
            HStack(spacing: 4) {
                Text("Paragraph")
                    .font(.system(size: 11, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.05))
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func insertHeading(_ prefix: String) {
        text += "\n" + prefix
    }
}

struct RichTextToolbar: View {
    @Binding var text: String
    let accent: Color
    @Binding var showPreview: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Paragraph style dropdown
                HeadingPicker(text: $text)

                ToolbarDivider()

                // Text formatting group
                HStack(spacing: 2) {
                    ToolbarButton(icon: "bold", help: "Bold (⌘B)") {
                        wrapSelection(with: "**")
                    }
                    ToolbarButton(icon: "italic", help: "Italic (⌘I)") {
                        wrapSelection(with: "_")
                    }
                    ToolbarButton(icon: "underline", help: "Underline") {
                        wrapSelection(prefix: "<u>", suffix: "</u>")
                    }
                    ToolbarButton(icon: "strikethrough", help: "Strikethrough") {
                        wrapSelection(with: "~~")
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )

                ToolbarDivider()

                // Lists group
                HStack(spacing: 2) {
                    ToolbarButton(icon: "list.bullet", help: "Bullet List") {
                        insertAtLineStart("- ")
                    }
                    ToolbarButton(icon: "list.number", help: "Numbered List") {
                        insertAtLineStart("1. ")
                    }
                    ToolbarButton(icon: "checklist", help: "Task List") {
                        insertAtLineStart("- [ ] ")
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )

                ToolbarDivider()

                // Insert group
                HStack(spacing: 2) {
                    ToolbarButton(icon: "link", help: "Insert Link") {
                        text += "[link text](https://)"
                    }
                    ToolbarButton(icon: "photo", help: "Insert Image") {
                        text += "![alt text](image-url)"
                    }
                    ToolbarButton(icon: "chevron.left.forwardslash.chevron.right", help: "Code Block") {
                        text += "\n```\ncode here\n```\n"
                    }
                    ToolbarButton(icon: "text.quote", help: "Quote") {
                        insertAtLineStart("> ")
                    }
                    ToolbarButton(icon: "minus", help: "Horizontal Rule") {
                        text += "\n---\n"
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )

                ToolbarDivider()

                // Table
                ToolbarButton(icon: "tablecells", help: "Insert Table") {
                    text += "\n| Column 1 | Column 2 | Column 3 |\n|----------|----------|----------|\n| Cell 1   | Cell 2   | Cell 3   |\n"
                }

                Spacer()

                // Preview toggle
                ToolbarButton(
                    icon: showPreview ? "eye.fill" : "eye",
                    label: showPreview ? "Hide Preview" : "Preview",
                    help: "Toggle Preview",
                    isActive: showPreview
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showPreview.toggle()
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(
            LinearGradient(
                colors: [Color.primary.opacity(0.04), Color.primary.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func wrapSelection(with wrapper: String) {
        wrapSelection(prefix: wrapper, suffix: wrapper)
    }

    private func wrapSelection(prefix: String, suffix: String) {
        text += prefix + "text" + suffix
    }

    private func insertAtLineStart(_ prefix: String) {
        text += "\n" + prefix
    }
}

struct MarkdownPreview: View {
    let text: String
    let accent: Color

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if text.isEmpty {
                    Text("Nothing to preview...")
                        .foregroundStyle(.tertiary)
                        .italic()
                } else {
                    Text(attributedMarkdown)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }

    private var attributedMarkdown: AttributedString {
        do {
            let attributed = try AttributedString(markdown: text, options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
            return attributed
        } catch {
            return AttributedString(text)
        }
    }
}

struct MarkdownEditor: View {
    @Binding var text: String
    let accent: Color
    @State private var showPreview = false

    var body: some View {
        VStack(spacing: 0) {
            // Rich Text Toolbar
            RichTextToolbar(text: $text, accent: accent, showPreview: $showPreview)

            Divider()

            // Editor or Split View
            if showPreview {
                HSplitView {
                    // Editor
                    editorView
                        .frame(minWidth: 250)

                    // Preview
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Image(systemName: "eye")
                                .font(.system(size: 11))
                            Text("Preview")
                                .font(.caption.weight(.medium))
                            Spacer()
                        }
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accent.opacity(0.06))

                        MarkdownPreview(text: text, accent: accent)
                    }
                    .frame(minWidth: 250)
                    .background(Color.primary.opacity(0.01))
                }
            } else {
                editorView
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .textBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var editorView: some View {
        VStack(spacing: 0) {
            TextEditor(text: $text)
                .font(.system(.body, design: .default))
                .scrollContentBackground(.hidden)
                .padding(16)
                .frame(minHeight: 200)

            // Character count footer
            HStack {
                Text("\(text.count) characters")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Markdown")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(accent.opacity(0.1))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }
}

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
                    // Notes section with Markdown
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notes & Thoughts", systemImage: "note.text")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        MarkdownEditor(text: $task.notes, accent: accent)
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

// MARK: - Commands

extension Notification.Name {
    static let focusInput = Notification.Name("TaskScratchpad.focusInput")
    static let toggleVisibility = Notification.Name("TaskScratchpad.toggleVisibility")
    static let clearCompleted = Notification.Name("TaskScratchpad.clearCompleted")
    static let newScratchpad = Notification.Name("TaskScratchpad.newScratchpad")
    static let exportData = Notification.Name("TaskScratchpad.exportData")
    static let importData = Notification.Name("TaskScratchpad.importData")
}

struct ScratchpadCommands: Commands {
    let store: TaskStore

    var body: some Commands {
        CommandMenu("Scratchpad") {
            Button("New Task") {
                NotificationCenter.default.post(name: .focusInput, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("New Tab") {
                NotificationCenter.default.post(name: .newScratchpad, object: nil)
            }
            .keyboardShortcut("t", modifiers: [.command])

            Divider()

            Button("Clear Completed") {
                NotificationCenter.default.post(name: .clearCompleted, object: nil)
            }
            .keyboardShortcut("k", modifiers: [.command])

            Divider()

            Button("Export All Data...") {
                NotificationCenter.default.post(name: .exportData, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Button("Import Data...") {
                NotificationCenter.default.post(name: .importData, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])

            Divider()

            Toggle("Float on Top", isOn: Bindable(store).isFloating)
        }
    }
}

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

// MARK: - App Entry

@main
struct TaskScratchpadApp: App {
    @State private var store = TaskStore()
    @State private var isWindowVisible = true

    var body: some Scene {
        WindowGroup {
            TaskScratchpadView(store: store)
                .modelContainer(for: [Scratchpad.self, TaskItem.self, SubTask.self])
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
