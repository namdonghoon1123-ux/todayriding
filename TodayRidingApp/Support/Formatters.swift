import Foundation

enum AppFormatters {
    static func distanceKm(_ meters: Double) -> String {
        String(format: "%.1f", meters / 1_000)
    }

    static func speedKmh(_ speed: Double) -> String {
        String(format: "%.1f", speed)
    }

    static func duration(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = seconds % 3_600 / 60
        let seconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

