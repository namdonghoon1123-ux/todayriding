import Combine
import CoreLocation
import Foundation
import TodayRidingCore

@MainActor
final class RideTrackingViewModel: ObservableObject {
    @Published private(set) var ride: Ride
    @Published private(set) var points: [RidePoint] = []
    @Published private(set) var trackingState: RideTrackingState = .recording

    private let tracker: RideTracker
    private let localStore: LocalRideStore
    private let rideSyncService: RideSyncService?
    private let weatherService: WeatherService?
    private var lastEvaluatedWeather: WeatherSnapshot?
    private var rainMonitorTask: Task<Void, Never>?
    private var mockCoordinate = GeoPoint(latitude: 37.5445, longitude: 127.0557)

    init(
        weather: WeatherSnapshot?,
        airQuality: AirQualitySnapshot?,
        tracker: RideTracker = RideTracker(),
        localStore: LocalRideStore,
        supabaseService: SupabaseService? = AppSupabaseServiceFactory.make(),
        weatherService: WeatherService? = AppWeatherServiceFactory.make()
    ) {
        self.tracker = tracker
        self.localStore = localStore
        self.rideSyncService = supabaseService.map(RideSyncService.init)
        self.weatherService = weatherService
        self.lastEvaluatedWeather = weather
        self.ride = tracker.start(weather: weather, airQuality: airQuality)

        Task {
            try? await localStore.saveRide(ride)
        }
    }

    /// 라이딩 중 주기적으로 날씨를 다시 확인해 비구름 접근 시 로컬 알림을 보낸다.
    func startRainMonitoring(interval: TimeInterval = 600) {
        guard let weatherService else { return }

        rainMonitorTask?.cancel()
        rainMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                guard !Task.isCancelled, let self else { return }
                await self.checkRain(using: weatherService)
            }
        }
    }

    func stopRainMonitoring() {
        rainMonitorTask?.cancel()
        rainMonitorTask = nil
    }

    private func checkRain(using service: WeatherService) async {
        guard trackingState == .recording else { return }
        guard let current = try? await service.currentWeather() else { return }

        if RainAlertEvaluator.shouldWarn(previous: lastEvaluatedWeather, current: current) {
            NotificationManager.shared.sendRainAlert(
                message: RainAlertEvaluator.warningMessage(for: current)
            )
        }
        lastEvaluatedWeather = current
    }

    func requestPauseOrResume() {
        switch trackingState {
        case .recording:
            tracker.pause()
        case .paused:
            tracker.resume()
        case .idle, .finished:
            break
        }

        trackingState = tracker.state
    }

    func record(location: CLLocation) {
        let coordinate = GeoPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        append(
            coordinate: coordinate,
            speedMps: location.speed >= 0 ? location.speed : nil,
            horizontalAccuracy: location.horizontalAccuracy,
            altitude: location.altitude
        )
    }

    func addMockPoint() {
        mockCoordinate = GeoPoint(
            latitude: mockCoordinate.latitude + 0.00045,
            longitude: mockCoordinate.longitude + 0.00035
        )
        append(
            coordinate: mockCoordinate,
            speedMps: 6.8,
            horizontalAccuracy: 8,
            altitude: nil
        )
    }

    func finish() async -> RideSummary {
        stopRainMonitoring()

        if let finishedRide = tracker.finish() {
            ride = finishedRide
        }
        trackingState = tracker.state

        try? await localStore.saveRide(ride)

        if let rideSyncService {
            let syncStatus = await rideSyncService.sync(ride: ride, points: points)
            ride.syncStatus = syncStatus
            try? await localStore.saveRide(ride)
        }

        await HealthKitWorkoutRecorder.save(ride: ride)

        return RideSummary(ride: ride, points: points)
    }

    private func append(
        coordinate: GeoPoint,
        speedMps: Double?,
        horizontalAccuracy: Double?,
        altitude: Double?
    ) {
        guard let updatedRide = tracker.appendLocation(
            coordinate: coordinate,
            speedMps: speedMps,
            horizontalAccuracy: horizontalAccuracy,
            altitude: altitude
        ) else {
            return
        }

        ride = updatedRide
        points = tracker.points

        if let lastPoint = points.last {
            Task {
                try? await localStore.appendPoint(lastPoint)
                try? await localStore.saveRide(updatedRide)
            }
        }
    }
}
