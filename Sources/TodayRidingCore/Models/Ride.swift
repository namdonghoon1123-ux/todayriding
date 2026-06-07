import Foundation

public struct Ride: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String?
    public let startedAt: Date
    public var endedAt: Date?
    public var durationSeconds: Int
    public var movingSeconds: Int
    public var distanceMeters: Double
    public var averageSpeedKmh: Double
    public var maxSpeedKmh: Double
    public var startCoordinate: GeoPoint?
    public var endCoordinate: GeoPoint?
    public var weatherSnapshot: WeatherSnapshot?
    public var airQualitySnapshot: AirQualitySnapshot?
    public var memo: String
    public var syncStatus: RideSyncStatus

    public init(
        id: UUID = UUID(),
        title: String? = nil,
        startedAt: Date,
        endedAt: Date? = nil,
        durationSeconds: Int = 0,
        movingSeconds: Int = 0,
        distanceMeters: Double = 0,
        averageSpeedKmh: Double = 0,
        maxSpeedKmh: Double = 0,
        startCoordinate: GeoPoint? = nil,
        endCoordinate: GeoPoint? = nil,
        weatherSnapshot: WeatherSnapshot? = nil,
        airQualitySnapshot: AirQualitySnapshot? = nil,
        memo: String = "",
        syncStatus: RideSyncStatus = .localOnly
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.durationSeconds = durationSeconds
        self.movingSeconds = movingSeconds
        self.distanceMeters = distanceMeters
        self.averageSpeedKmh = averageSpeedKmh
        self.maxSpeedKmh = maxSpeedKmh
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        self.weatherSnapshot = weatherSnapshot
        self.airQualitySnapshot = airQualitySnapshot
        self.memo = memo
        self.syncStatus = syncStatus
    }
}

public enum RideSyncStatus: String, Codable, Sendable {
    case localOnly
    case pending
    case synced
    case failed
}
