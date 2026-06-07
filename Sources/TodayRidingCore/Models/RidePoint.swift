import Foundation

public struct RidePoint: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public let rideID: UUID
    public let recordedAt: Date
    public let coordinate: GeoPoint
    public let altitude: Double?
    public let speedMps: Double?
    public let horizontalAccuracy: Double?
    public let sequence: Int

    public init(
        id: UUID = UUID(),
        rideID: UUID,
        recordedAt: Date,
        coordinate: GeoPoint,
        altitude: Double? = nil,
        speedMps: Double? = nil,
        horizontalAccuracy: Double? = nil,
        sequence: Int
    ) {
        self.id = id
        self.rideID = rideID
        self.recordedAt = recordedAt
        self.coordinate = coordinate
        self.altitude = altitude
        self.speedMps = speedMps
        self.horizontalAccuracy = horizontalAccuracy
        self.sequence = sequence
    }
}
