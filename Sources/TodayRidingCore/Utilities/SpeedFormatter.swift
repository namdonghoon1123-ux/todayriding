import Foundation

public enum SpeedFormatter {
    public static func kmh(meters: Double, seconds: Int) -> Double {
        guard seconds > 0 else { return 0 }
        return meters / Double(seconds) * 3.6
    }

    public static func oneDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

