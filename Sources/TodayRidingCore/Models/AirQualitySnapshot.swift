import Foundation

public struct AirQualitySnapshot: Codable, Equatable, Sendable {
    public let pm10: Int
    public let pm25: Int
    public let stationName: String
    public let measuredAt: Date

    public init(pm10: Int, pm25: Int, stationName: String, measuredAt: Date) {
        self.pm10 = pm10
        self.pm25 = pm25
        self.stationName = stationName
        self.measuredAt = measuredAt
    }

    public var pm25Grade: AirQualityGrade {
        switch pm25 {
        case ..<16:
            return .good
        case 16..<36:
            return .normal
        case 36..<76:
            return .bad
        default:
            return .veryBad
        }
    }
}

public enum AirQualityGrade: String, Codable, Sendable {
    case good
    case normal
    case bad
    case veryBad
}
