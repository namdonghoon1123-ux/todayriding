import Foundation

public struct WeatherSnapshot: Codable, Equatable, Sendable {
    public let observedAt: Date
    public let locationName: String
    public let temperatureCelsius: Double
    public let feelsLikeCelsius: Double
    public let humidityPercent: Int
    public let precipitationProbabilityPercent: Int
    public let precipitationType: PrecipitationType
    public let skyCondition: String
    public let cloudDescription: String
    public let windSpeedMps: Double
    public let windDirection: String
    public let sunsetAt: Date

    public init(
        observedAt: Date,
        locationName: String,
        temperatureCelsius: Double,
        feelsLikeCelsius: Double,
        humidityPercent: Int,
        precipitationProbabilityPercent: Int,
        precipitationType: PrecipitationType,
        skyCondition: String,
        cloudDescription: String,
        windSpeedMps: Double,
        windDirection: String,
        sunsetAt: Date
    ) {
        self.observedAt = observedAt
        self.locationName = locationName
        self.temperatureCelsius = temperatureCelsius
        self.feelsLikeCelsius = feelsLikeCelsius
        self.humidityPercent = humidityPercent
        self.precipitationProbabilityPercent = precipitationProbabilityPercent
        self.precipitationType = precipitationType
        self.skyCondition = skyCondition
        self.cloudDescription = cloudDescription
        self.windSpeedMps = windSpeedMps
        self.windDirection = windDirection
        self.sunsetAt = sunsetAt
    }
}

public enum PrecipitationType: String, Codable, Sendable {
    case none
    case rain
    case rainAndSnow
    case snow
    case shower

    public var label: String {
        switch self {
        case .none:
            return "없음"
        case .rain:
            return "비"
        case .rainAndSnow:
            return "비/눈"
        case .snow:
            return "눈"
        case .shower:
            return "소나기"
        }
    }
}
