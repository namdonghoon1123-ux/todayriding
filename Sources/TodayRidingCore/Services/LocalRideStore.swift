import Foundation

public protocol LocalRideStore: Sendable {
    func saveRide(_ ride: Ride) async throws
    func appendPoint(_ point: RidePoint) async throws
    func loadPendingRides() async throws -> [Ride]
    func loadPoints(for rideID: UUID) async throws -> [RidePoint]
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

    public func loadPoints(for rideID: UUID) async throws -> [RidePoint] {
        pointsByRideID[rideID] ?? []
    }
}

public actor FileRideStore: LocalRideStore {
    private let directoryURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directoryURL: URL) {
        self.directoryURL = directoryURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func saveRide(_ ride: Ride) async throws {
        try ensureStoreDirectoryExists()
        let data = try encoder.encode(ride)
        try data.write(to: rideURL(for: ride.id), options: [.atomic])
    }

    public func appendPoint(_ point: RidePoint) async throws {
        try ensureStoreDirectoryExists()
        var points = try await loadPoints(for: point.rideID)
        points.append(point)
        let data = try encoder.encode(points)
        try data.write(to: pointsURL(for: point.rideID), options: [.atomic])
    }

    public func loadPendingRides() async throws -> [Ride] {
        try ensureStoreDirectoryExists()

        return try FileManager.default
            .contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            .filter { $0.pathExtension == "ride" }
            .compactMap { url in
                let data = try Data(contentsOf: url)
                return try decoder.decode(Ride.self, from: data)
            }
            .filter { $0.syncStatus == .pending || $0.syncStatus == .failed || $0.syncStatus == .localOnly }
            .sorted { $0.startedAt < $1.startedAt }
    }

    public func loadPoints(for rideID: UUID) async throws -> [RidePoint] {
        let url = pointsURL(for: rideID)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode([RidePoint].self, from: data)
    }

    private func ensureStoreDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    private func rideURL(for rideID: UUID) -> URL {
        directoryURL.appendingPathComponent("\(rideID.uuidString).ride")
    }

    private func pointsURL(for rideID: UUID) -> URL {
        directoryURL.appendingPathComponent("\(rideID.uuidString).points")
    }
}
