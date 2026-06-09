import Foundation

public struct UVIndexSnapshot: Codable, Equatable, Sendable {
    public let value: Int
    public let category: UVCategory
    public let observedAt: Date
    public let source: String

    public init(value: Int, category: UVCategory, observedAt: Date, source: String) {
        self.value = value
        self.category = category
        self.observedAt = observedAt
        self.source = source
    }
}

public enum UVCategory: String, Codable, Sendable {
    case low
    case moderate
    case high
    case veryHigh
    case extreme

    public var label: String {
        switch self {
        case .low: return "낮음"
        case .moderate: return "보통"
        case .high: return "높음"
        case .veryHigh: return "매우 높음"
        case .extreme: return "위험"
        }
    }

    public static func category(for value: Int) -> UVCategory {
        switch value {
        case ..<3: return .low
        case 3..<6: return .moderate
        case 6..<8: return .high
        case 8..<11: return .veryHigh
        default: return .extreme
        }
    }
}
