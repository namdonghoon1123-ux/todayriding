import Foundation

public final class RideTracker: @unchecked Sendable {
    public private(set) var ride: Ride?
    public private(set) var points: [RidePoint] = []
    public private(set) var state: RideTrackingState = .idle

    private let clock: @Sendable () -> Date

    public init(clock: @escaping @Sendable () -> Date = Date.init) {
        self.clock = clock
    }

    public func start(weather: WeatherSnapshot?, airQuality: AirQualitySnapshot?) -> Ride {
        let now = clock()
        let newRide = Ride(
            startedAt: now,
            weatherSnapshot: weather,
            airQualitySnapshot: airQuality
        )
        ride = newRide
        points = []
        state = .recording
        return newRide
    }

    public func pause() {
        guard state == .recording else { return }
        state = .paused
    }

    public func resume() {
        guard state == .paused else { return }
        state = .recording
    }

    public func appendLocation(
        coordinate: GeoPoint,
        speedMps: Double?,
        horizontalAccuracy: Double?,
        altitude: Double? = nil
    ) -> Ride? {
        guard state == .recording, var currentRide = ride else {
            return ride
        }

        let point = RidePoint(
            rideID: currentRide.id,
            recordedAt: clock(),
            coordinate: coordinate,
            altitude: altitude,
            speedMps: speedMps,
            horizontalAccuracy: horizontalAccuracy,
            sequence: points.count
        )
        points.append(point)

        if points.count == 1 {
            currentRide.startCoordinate = coordinate
        }

        currentRide.endCoordinate = coordinate
        currentRide.distanceMeters = DistanceCalculator.totalDistanceMeters(points.map(\.coordinate))
        currentRide.durationSeconds = Int(point.recordedAt.timeIntervalSince(currentRide.startedAt))
        currentRide.movingSeconds = currentRide.durationSeconds
        currentRide.averageSpeedKmh = SpeedFormatter.kmh(
            meters: currentRide.distanceMeters,
            seconds: currentRide.movingSeconds
        )

        if let speedMps, speedMps >= 0 {
            currentRide.maxSpeedKmh = max(currentRide.maxSpeedKmh, speedMps * 3.6)
        }

        ride = currentRide
        return currentRide
    }

    public func finish(memo: String = "") -> Ride? {
        guard var currentRide = ride else { return nil }
        let endedAt = clock()
        currentRide.endedAt = endedAt
        currentRide.durationSeconds = max(currentRide.durationSeconds, Int(endedAt.timeIntervalSince(currentRide.startedAt)))
        currentRide.movingSeconds = currentRide.durationSeconds
        currentRide.memo = memo
        currentRide.syncStatus = .pending
        ride = currentRide
        state = .finished
        return currentRide
    }
}

public enum RideTrackingState: Sendable {
    case idle
    case recording
    case paused
    case finished
}

