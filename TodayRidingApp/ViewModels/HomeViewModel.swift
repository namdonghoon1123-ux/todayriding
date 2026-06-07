import Combine
import Foundation
import TodayRidingCore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var weather: WeatherSnapshot?
    @Published private(set) var airQuality: AirQualitySnapshot?
    @Published private(set) var recommendation: RidingRecommendation?
    @Published private(set) var isLoading = false

    private let weatherService: WeatherService
    private let airQualityService: AirQualityService

    init(
        weatherService: WeatherService = MockWeatherService(),
        airQualityService: AirQualityService = MockAirQualityService()
    ) {
        self.weatherService = weatherService
        self.airQualityService = airQualityService
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let weather = weatherService.currentWeather()
            async let airQuality = airQualityService.currentAirQuality()
            let loadedWeather = try await weather
            let loadedAirQuality = try await airQuality

            self.weather = loadedWeather
            self.airQuality = loadedAirQuality
            recommendation = RidingScoreCalculator.recommendation(
                weather: loadedWeather,
                airQuality: loadedAirQuality
            )
        } catch {
            // MVP: keep the screen usable with mock service defaults.
            recommendation = nil
        }
    }
}
