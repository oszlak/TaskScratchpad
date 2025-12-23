import SwiftUI

// MARK: - Color Palette

public enum ColorPalette {
    public static let colors: [String] = [
        "#6EA8FE", "#8F7CFF", "#F39C12", "#FF6F61",
        "#1ABC9C", "#E67E22", "#5DADE2", "#AF7AC5"
    ]

    public static func color(at index: Int) -> String {
        colors[index % colors.count]
    }
}

// MARK: - Color from Hex

public extension Color {
    init?(hex: String) {
        guard let rgb = Self.parseHex(hex) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }

    static func parseHex(_ hex: String) -> Int? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        guard hexString.count == 6 else { return nil }
        return Int(hexString, radix: 16)
    }

    static func isValidHex(_ hex: String) -> Bool {
        parseHex(hex) != nil
    }
}

