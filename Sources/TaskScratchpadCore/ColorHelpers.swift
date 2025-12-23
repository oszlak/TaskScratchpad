import SwiftUI

// MARK: - Color Palette

public enum ColorPalette {
    // Warm, friendly color palette
    public static let colors: [String] = [
        "#E8A87C", // Warm peach
        "#C38D9E", // Dusty rose
        "#41B3A3", // Soft teal
        "#E27D60", // Terracotta
        "#85CDCA", // Mint
        "#D4A574", // Caramel
        "#A8D8EA", // Sky blue
        "#F6D55C"  // Warm yellow
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

