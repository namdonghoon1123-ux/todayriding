import Foundation

public struct RideSummary: Codable, Equatable, Sendable {
    public let ride: Ride
    public let points: [RidePoint]

    public init(ride: Ride, points: [RidePoint]) {
        self.ride = ride
        self.points = points
    }
}
