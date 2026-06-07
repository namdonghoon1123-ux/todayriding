import Foundation

public protocol WeatherService: Sendable {
    func currentWeather() async throws -> WeatherSnapshot
}

public struct KMAWeatherService: WeatherService {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func currentWeather() async throws -> WeatherSnapshot {
        _ = apiKey
        throw RemoteServiceError.notImplemented("KMAWeatherService requires KMA grid conversion and endpoint mapping.")
    }
}

public struct MockWeatherService: WeatherService {
    public init() {}

    public func currentWeather() async throws -> WeatherSnapshot {
        let now = Date()
        let sunset = Calendar.current.date(bySettingHour: 19, minute: 42, second: 0, of: now) ?? now

        return WeatherSnapshot(
            observedAt: now,
            locationName: "서울 성동구",
            temperatureCelsius: 23,
            feelsLikeCelsius: 22,
            humidityPercent: 58,
            precipitationProbabilityPercent: 20,
            precipitationType: .none,
            skyCondition: "맑음",
            cloudDescription: "구름 조금",
            windSpeedMps: 3.2,
            windDirection: "서풍",
            sunsetAt: sunset
        )
    }
}

public enum RemoteServiceError: Error, Sendable {
    case notImplemented(String)
    case notConfigured(String)
}
