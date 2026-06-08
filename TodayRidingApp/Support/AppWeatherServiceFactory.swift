import Foundation
import TodayRidingCore

/// 기상청 키가 주입돼 있으면 실제 `KMAWeatherService`, 아니면 `MockWeatherService`.
enum AppWeatherServiceFactory {
    static func make(coordinate: GeoPoint = AppConfiguration.defaultCoordinate) -> WeatherService {
        guard let apiKey = AppConfiguration.string(for: "TODAYRIDING_KMA_API_KEY") else {
            return MockWeatherService()
        }

        return KMAWeatherService(apiKey: apiKey, coordinate: coordinate)
    }
}
