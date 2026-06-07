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
    private var mockCoordinate = GeoPoint(latitude: 37.5445, longitude: 127.0557)

    init(
        weather: WeatherSnapshot?,
        airQuality: AirQualitySnapshot?,
        tracker: RideTracker = RideTracker(),
        localStore: LocalRideStore = InMemoryRideStore()
    ) {
        self.tracker = tracker
        self.localStore = localStore
        self.ride = tracker.start(weather: weather, airQuality: airQuality)

        Task {
            try? await localStore.saveRide(ride)
        }
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

    func finish() -> RideSummary {
        if let finishedRide = tracker.finish() {
            ride = finishedRide
        }
        trackingState = tracker.state

        Task {
            try? await localStore.saveRide(ride)
        }

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
