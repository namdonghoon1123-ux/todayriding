import Foundation

public protocol LocalRideStore: Sendable {
    func saveRide(_ ride: Ride) async throws
    func appendPoint(_ point: RidePoint) async throws
    func loadPendingRides() async throws -> [Ride]
}

public actor InMemoryRideStore: LocalRideStore {
    private var rides: [UUID: Ride] = [:]
    private var pointsByRideID: [UUID: [RidePoint]] = [:]

    public init() {}

    public func saveRide(_ ride: Ride) async throws {
        rides[ride.id] = ride
    }

    public func appendPoint(_ point: RidePoint) async throws {
        pointsByRideID[point.rideID, default: []].append(point)
    }

    public func loadPendingRides() async throws -> [Ride] {
        rides.values
            .filter { $0.syncStatus == .pending || $0.syncStatus == .failed || $0.syncStatus == .localOnly }
            .sorted { $0.startedAt < $1.startedAt }
    }
}

