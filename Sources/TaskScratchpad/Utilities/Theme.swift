import SwiftUI

// MARK: - UI Theme

enum AppTheme {
    static let cardBackground = Color.primary.opacity(0.03)
    static let cardBackgroundHover = Color.primary.opacity(0.06)
    static let cardBorder = Color.primary.opacity(0.08)
    static let inputBackground = Color(hex: "#FDF6E3")?.opacity(0.3) ?? Color.primary.opacity(0.05)
    static let emptyStateColor = Color(hex: "#D4A574") ?? .secondary
}

