import SwiftUI

enum AppTheme {
    static let background = Color(hex: 0x0B0F14)
    static let surface = Color(hex: 0x11161D)
    static let surface2 = Color(hex: 0x161C24)
    static let brand = Color(hex: 0xFF6B35)
    static let good = Color(hex: 0x3BD17F)
    static let ok = Color(hex: 0xE8B563)
    static let bad = Color(hex: 0xFF5247)
    static let textSecondary = Color(hex: 0x9AA3AF)
    static let textTertiary = Color(hex: 0x7C8694)
    static let hairline = Color.white.opacity(0.08)
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

