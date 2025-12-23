import Foundation

// MARK: - Relative Date Formatting

public extension Date {
    /// Returns a human-readable relative time string (e.g., "2m ago", "1h ago")
    func relativeString(from now: Date = Date()) -> String {
        let interval = now.timeIntervalSince(self)

        if interval < 0 {
            return "future"
        }
        if interval < 60 {
            return "now"
        }
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        }
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
        if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Time Interval Helpers

public extension TimeInterval {
    static let minute: TimeInterval = 60
    static let hour: TimeInterval = 3600
    static let day: TimeInterval = 86400
    static let week: TimeInterval = 604800
}

