import Combine
import Foundation
import TodayRidingCore

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var weather: WeatherSnapshot?
    @Published private(set) var airQuality: AirQualitySnapshot?
    @Published private(set) var uvIndex: UVIndexSnapshot?
    @Published private(set) var recommendation: RidingRecommendation?
    @Published private(set) var coachAdvice: RidingCoachAdvice?
    @Published private(set) var isLoading = false

    private let makeWeatherService: (GeoPoint) -> WeatherService
    private let makeAirQualityService: (GeoPoint) -> AirQualityService
    private let makeUVIndexService: (GeoPoint) -> UVIndexService
    private let localStore: LocalRideStore?
    private var coordinate: GeoPoint

    init(
        coordinate: GeoPoint = AppConfiguration.defaultCoordinate,
        makeWeatherService: @escaping (GeoPoint) -> WeatherService = AppWeatherServiceFactory.make(coordinate:),
        makeAirQualityService: @escaping (GeoPoint) -> AirQualityService = AppAirQualityServiceFactory.make(coordinate:),
        makeUVIndexService: @escaping (GeoPoint) -> UVIndexService = AppUVIndexServiceFactory.make(coordinate:),
        localStore: LocalRideStore? = nil
    ) {
        self.coordinate = coordinate
        self.makeWeatherService = makeWeatherService
        self.makeAirQualityService = makeAirQualityService
        self.makeUVIndexService = makeUVIndexService
        self.localStore = localStore
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let weatherService = makeWeatherService(coordinate)
        let airQualityService = makeAirQualityService(coordinate)
        let uvService = makeUVIndexService(coordinate)

        do {
            async let weather = weatherService.currentWeather()
            async let airQuality = airQualityService.currentAirQuality()
            async let uv = uvService.currentUVIndex()
            let loadedWeather = try await weather
            let loadedAirQuality = try await airQuality
            let loadedUV = try await uv

            self.weather = loadedWeather
            self.airQuality = loadedAirQuality
            self.uvIndex = loadedUV
            recommendation = RidingScoreCalculator.recommendation(
                weather: loadedWeather,
                airQuality: loadedAirQuality
            )
        } catch {
            // MVP: keep the screen usable with mock service defaults.
            recommendation = nil
        }

        await refreshCoachAdvice()
    }

    /// 실기기 GPS 좌표로 갱신. 위치가 충분히 바뀌었거나 아직 데이터가 없으면 다시 로드한다.
    func updateCoordinate(_ newCoordinate: GeoPoint) async {
        let movedEnough = DistanceCalculator.distanceMeters(from: coordinate, to: newCoordinate) > 100
        guard movedEnough || weather == nil else { return }

        coordinate = newCoordinate
        await load()
    }

    private func refreshCoachAdvice() async {
        guard let localStore else {
            coachAdvice = RidingCoach.advice(rides: [], recommendation: recommendation)
            return
        }
        let rides = (try? await localStore.loadRides()) ?? []
        coachAdvice = RidingCoach.advice(rides: rides, recommendation: recommendation)
    }
}
