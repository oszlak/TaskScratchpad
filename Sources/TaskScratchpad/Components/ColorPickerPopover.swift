import SwiftUI

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

