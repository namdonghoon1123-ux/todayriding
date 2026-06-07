import Foundation

public struct RidingRecommendation: Codable, Equatable, Sendable {
    public let score: Int
    public let grade: RidingScoreGrade
    public let message: String
    public let warnings: [String]

    public init(score: Int, grade: RidingScoreGrade, message: String, warnings: [String]) {
        self.score = score
        self.grade = grade
        self.message = message
        self.warnings = warnings
    }
}

public enum RidingScoreGrade: String, Codable, Sendable {
    case excellent
    case good
    case caution
    case shortOnly
    case notRecommended

    public var label: String {
        switch self {
        case .excellent:
            return "매우 좋음"
        case .good:
            return "좋음"
        case .caution:
            return "주의"
        case .shortOnly:
            return "짧게 추천"
        case .notRecommended:
            return "비추천"
        }
    }
}
