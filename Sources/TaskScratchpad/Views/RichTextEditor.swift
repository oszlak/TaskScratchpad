import SwiftUI
import AppKit

// MARK: - Rich Text Editor (WYSIWYG)

/// Coordinator for the RichTextEditor NSTextView
class RichTextCoordinator: NSObject, NSTextViewDelegate {
    var parent: RichTextEditorView
    var textView: NSTextView?

    init(_ parent: RichTextEditorView) {
        self.parent = parent
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        // Convert attributed string to RTF data and store as base64 in parent.text
        if let rtfData = textView.textStorage?.rtf(from: NSRange(location: 0, length: textView.textStorage?.length ?? 0), documentAttributes: [:]) {
            parent.text = rtfData.base64EncodedString()
        }
    }
}

/// NSViewRepresentable for a rich text NSTextView
struct RichTextEditorView: NSViewRepresentable {
    @Binding var text: String
    let accent: Color

    func makeCoordinator() -> RichTextCoordinator {
        RichTextCoordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        // Configure text view
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.usesRuler = false
        textView.importsGraphics = false
        textView.allowsImageEditing = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false

        // Appearance
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.font = NSFont.systemFont(ofSize: 14)

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        // Load existing content
        loadContent(into: textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // Only update if text changed externally (not from our own edits)
    }

    private func loadContent(into textView: NSTextView) {
        if let data = Data(base64Encoded: text),
           let attributedString = NSAttributedString(rtf: data, documentAttributes: nil) {
            textView.textStorage?.setAttributedString(attributedString)
        } else if !text.isEmpty && Data(base64Encoded: text) == nil {
            // Plain text fallback
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.textColor
            ]
            textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: attrs))
        }
    }
}

/// Formatting action enum
enum FormattingAction {
    case bold, italic, underline, strikethrough
    case heading1, heading2, heading3
    case bulletList, numberedList
    case link, code
    case alignLeft, alignCenter, alignRight
}

/// Observable class to handle formatting commands
@Observable
class RichTextController {
    weak var textView: NSTextView?

    func applyFormatting(_ action: FormattingAction) {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }

        let selectedRange = textView.selectedRange()
        let hasSelection = selectedRange.length > 0

        textView.undoManager?.beginUndoGrouping()

        switch action {
        case .bold:
            toggleTrait(.bold, in: textStorage, range: selectedRange, hasSelection: hasSelection)
        case .italic:
            toggleTrait(.italic, in: textStorage, range: selectedRange, hasSelection: hasSelection)
        case .underline:
            toggleAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, in: textStorage, range: selectedRange, hasSelection: hasSelection)
        case .strikethrough:
            toggleAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, in: textStorage, range: selectedRange, hasSelection: hasSelection)
        case .heading1:
            applyFontSize(24, bold: true, in: textStorage, range: selectedRange, hasSelection: hasSelection)
        case .heading2:
            applyFontSize(20, bold: true, in: textStorage, range: selectedRange, hasSelection: hasSelection)
        case .heading3:
            applyFontSize(17, bold: true, in: textStorage, range: selectedRange, hasSelection: hasSelection)
        case .bulletList:
            insertBullet(in: textView)
        case .numberedList:
            insertNumberedItem(in: textView)
        case .link:
            insertLink(in: textView)
        case .code:
            applyCodeStyle(in: textStorage, range: selectedRange, hasSelection: hasSelection)
        case .alignLeft:
            applyAlignment(.left, in: textStorage, range: selectedRange)
        case .alignCenter:
            applyAlignment(.center, in: textStorage, range: selectedRange)
        case .alignRight:
            applyAlignment(.right, in: textStorage, range: selectedRange)
        }

        textView.undoManager?.endUndoGrouping()
        textView.didChangeText()
    }

    private func toggleTrait(_ trait: NSFontDescriptor.SymbolicTraits, in storage: NSTextStorage, range: NSRange, hasSelection: Bool) {
        if hasSelection {
            storage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
                guard let font = value as? NSFont else { return }
                let descriptor = font.fontDescriptor
                let newDescriptor: NSFontDescriptor

                if descriptor.symbolicTraits.contains(trait) {
                    var traits = descriptor.symbolicTraits
                    traits.remove(trait)
                    newDescriptor = descriptor.withSymbolicTraits(traits)
                } else {
                    newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait))
                }

                let newFont = NSFont(descriptor: newDescriptor, size: font.pointSize) ?? font
                storage.addAttribute(.font, value: newFont, range: attrRange)
            }
        } else {
            // Set typing attributes for cursor position
            var attrs = textView?.typingAttributes ?? [:]
            let font = attrs[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
            let descriptor = font.fontDescriptor
            let newDescriptor: NSFontDescriptor

            if descriptor.symbolicTraits.contains(trait) {
                var traits = descriptor.symbolicTraits
                traits.remove(trait)
                newDescriptor = descriptor.withSymbolicTraits(traits)
            } else {
                newDescriptor = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait))
            }

            let newFont = NSFont(descriptor: newDescriptor, size: font.pointSize) ?? font
            attrs[.font] = newFont
            textView?.typingAttributes = attrs
        }
    }

    private func toggleAttribute(_ key: NSAttributedString.Key, value: Any, in storage: NSTextStorage, range: NSRange, hasSelection: Bool) {
        if hasSelection {
            var hasAttribute = false
            storage.enumerateAttribute(key, in: range, options: []) { val, _, stop in
                if val != nil {
                    hasAttribute = true
                    stop.pointee = true
                }
            }

            if hasAttribute {
                storage.removeAttribute(key, range: range)
            } else {
                storage.addAttribute(key, value: value, range: range)
            }
        } else {
            var attrs = textView?.typingAttributes ?? [:]
            if attrs[key] != nil {
                attrs.removeValue(forKey: key)
            } else {
                attrs[key] = value
            }
            textView?.typingAttributes = attrs
        }
    }

    private func applyFontSize(_ size: CGFloat, bold: Bool, in storage: NSTextStorage, range: NSRange, hasSelection: Bool) {
        let range = hasSelection ? range : lineRange(for: range, in: storage)

        storage.enumerateAttribute(.font, in: range, options: []) { value, attrRange, _ in
            var font = value as? NSFont ?? NSFont.systemFont(ofSize: size)
            if bold {
                font = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            }
            font = NSFontManager.shared.convert(font, toSize: size)
            storage.addAttribute(.font, value: font, range: attrRange)
        }
    }

    private func lineRange(for range: NSRange, in storage: NSTextStorage) -> NSRange {
        let string = storage.string as NSString
        return string.lineRange(for: range)
    }

    private func insertBullet(in textView: NSTextView) {
        let insertion = "\n• "
        textView.insertText(insertion, replacementRange: textView.selectedRange())
    }

    private func insertNumberedItem(in textView: NSTextView) {
        let insertion = "\n1. "
        textView.insertText(insertion, replacementRange: textView.selectedRange())
    }

    private func insertLink(in textView: NSTextView) {
        let selectedRange = textView.selectedRange()
        if selectedRange.length > 0 {
            // Wrap selected text as link
            if let text = (textView.string as NSString).substring(with: selectedRange) as String? {
                let linkString = NSAttributedString(string: text, attributes: [
                    .link: URL(string: "https://")!,
                    .foregroundColor: NSColor.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ])
                textView.textStorage?.replaceCharacters(in: selectedRange, with: linkString)
            }
        } else {
            textView.insertText("[Link](https://)", replacementRange: selectedRange)
        }
    }

    private func applyCodeStyle(in storage: NSTextStorage, range: NSRange, hasSelection: Bool) {
        let monoFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let bgColor = NSColor.quaternaryLabelColor

        if hasSelection {
            storage.addAttributes([
                .font: monoFont,
                .backgroundColor: bgColor
            ], range: range)
        } else {
            var attrs = textView?.typingAttributes ?? [:]
            attrs[.font] = monoFont
            attrs[.backgroundColor] = bgColor
            textView?.typingAttributes = attrs
        }
    }

    private func applyAlignment(_ alignment: NSTextAlignment, in storage: NSTextStorage, range: NSRange) {
        let lineRange = self.lineRange(for: range, in: storage)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        storage.addAttribute(.paragraphStyle, value: paragraphStyle, range: lineRange)
    }
}

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
            .padding(.horizontal, 6)
    }
}

struct RichTextToolbar: View {
    let controller: RichTextController
    let accent: Color

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Heading dropdown
                Menu {
                    Button("Normal Text") { controller.applyFormatting(.heading3) }
                    Divider()
                    Button("Heading 1") { controller.applyFormatting(.heading1) }
                    Button("Heading 2") { controller.applyFormatting(.heading2) }
                    Button("Heading 3") { controller.applyFormatting(.heading3) }
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

                ToolbarDivider()

                // Text formatting
                HStack(spacing: 2) {
                    ToolbarButton(icon: "bold", help: "Bold (⌘B)") {
                        controller.applyFormatting(.bold)
                    }
                    ToolbarButton(icon: "italic", help: "Italic (⌘I)") {
                        controller.applyFormatting(.italic)
                    }
                    ToolbarButton(icon: "underline", help: "Underline (⌘U)") {
                        controller.applyFormatting(.underline)
                    }
                    ToolbarButton(icon: "strikethrough", help: "Strikethrough") {
                        controller.applyFormatting(.strikethrough)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )

                ToolbarDivider()

                // Lists
                HStack(spacing: 2) {
                    ToolbarButton(icon: "list.bullet", help: "Bullet List") {
                        controller.applyFormatting(.bulletList)
                    }
                    ToolbarButton(icon: "list.number", help: "Numbered List") {
                        controller.applyFormatting(.numberedList)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )

                ToolbarDivider()

                // Insert
                HStack(spacing: 2) {
                    ToolbarButton(icon: "link", help: "Insert Link") {
                        controller.applyFormatting(.link)
                    }
                    ToolbarButton(icon: "chevron.left.forwardslash.chevron.right", help: "Code") {
                        controller.applyFormatting(.code)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )

                ToolbarDivider()

                // Alignment
                HStack(spacing: 2) {
                    ToolbarButton(icon: "text.alignleft", help: "Align Left") {
                        controller.applyFormatting(.alignLeft)
                    }
                    ToolbarButton(icon: "text.aligncenter", help: "Align Center") {
                        controller.applyFormatting(.alignCenter)
                    }
                    ToolbarButton(icon: "text.alignright", help: "Align Right") {
                        controller.applyFormatting(.alignRight)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primary.opacity(0.03))
                )

                Spacer()
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
}

/// NSViewRepresentable wrapper that connects to RichTextController
struct RichTextNSViewRepresentable: NSViewRepresentable {
    @Binding var text: String
    let controller: RichTextController

    func makeCoordinator() -> RichTextCoordinator {
        RichTextCoordinator(self)
    }

    class RichTextCoordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextNSViewRepresentable

        init(_ parent: RichTextNSViewRepresentable) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            if let rtfData = textView.textStorage?.rtf(from: NSRange(location: 0, length: textView.textStorage?.length ?? 0), documentAttributes: [:]) {
                parent.text = rtfData.base64EncodedString()
            }
        }
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        controller.textView = textView

        // Configure
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.usesFindBar = true
        textView.usesRuler = false
        textView.importsGraphics = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false

        // Appearance
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.font = NSFont.systemFont(ofSize: 14)

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        // Load existing content
        loadContent(into: textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        // Handled by delegate
    }

    private func loadContent(into textView: NSTextView) {
        if let data = Data(base64Encoded: text),
           let attributedString = NSAttributedString(rtf: data, documentAttributes: nil) {
            textView.textStorage?.setAttributedString(attributedString)
        } else if !text.isEmpty && Data(base64Encoded: text) == nil {
            // Plain text fallback
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.textColor
            ]
            textView.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: attrs))
        }
    }
}

struct RichTextEditor: View {
    @Binding var text: String
    let accent: Color
    @State private var controller = RichTextController()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            RichTextToolbar(controller: controller, accent: accent)

            Divider()

            // Editor
            RichTextNSViewRepresentable(text: $text, controller: controller)
                .frame(minHeight: 200)

            // Footer
            HStack {
                Image(systemName: "textformat")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text("Rich Text")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Select text → click toolbar to format")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.02))
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
}

