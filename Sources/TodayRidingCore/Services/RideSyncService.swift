import Foundation

public protocol SupabaseService: Sendable {
    func uploadRide(_ ride: Ride, points: [RidePoint]) async throws
}

public struct NoopSupabaseService: SupabaseService {
    public init() {}

    public func uploadRide(_ ride: Ride, points: [RidePoint]) async throws {
        _ = ride
        _ = points
    }
}

public struct RideSyncService: Sendable {
    private let supabaseService: SupabaseService

    public init(supabaseService: SupabaseService) {
        self.supabaseService = supabaseService
    }

    public func sync(ride: Ride, points: [RidePoint]) async -> RideSyncStatus {
        do {
            try await supabaseService.uploadRide(ride, points: points)
            return .synced
        } catch {
            return .pending
        }
    }
}

public struct SupabaseConfiguration: Sendable {
    public let projectURL: URL
    public let anonKey: String

    public init(projectURL: URL, anonKey: String) {
        self.projectURL = projectURL
        self.anonKey = anonKey
    }
}

public struct HTTPSupabaseService: SupabaseService {
    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder

    public init(
        configuration: SupabaseConfiguration,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.session = session

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    public func uploadRide(_ ride: Ride, points: [RidePoint]) async throws {
        try await post(
            path: "rides",
            body: SupabaseRidePayload(ride: ride)
        )

        if !points.isEmpty {
            try await post(
                path: "ride_points",
                body: points.map(SupabaseRidePointPayload.init)
            )
        }
    }

    private func post<T: Encodable>(path: String, body: T) async throws {
        let url = configuration.projectURL
            .appendingPathComponent("rest/v1")
            .appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(configuration.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(body)

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode)
        else {
            throw SupabaseUploadError.requestFailed
        }
    }
}

public enum SupabaseUploadError: Error, Sendable {
    case requestFailed
}

private struct SupabaseRidePayload: Encodable {
    let id: UUID
    let user_id: UUID?
    let title: String?
    let started_at: Date
    let ended_at: Date?
    let duration_seconds: Int
    let moving_seconds: Int
    let distance_meters: Double
    let average_speed_kmh: Double
    let max_speed_kmh: Double
    let start_lat: Double?
    let start_lng: Double?
    let end_lat: Double?
    let end_lng: Double?
    let weather_snapshot: WeatherSnapshot?
    let air_quality_snapshot: AirQualitySnapshot?
    let memo: String?
    let share_card_url: String?
    let sync_status: String

    init(ride: Ride) {
        id = ride.id
        user_id = nil
        title = ride.title
        started_at = ride.startedAt
        ended_at = ride.endedAt
        duration_seconds = ride.durationSeconds
        moving_seconds = ride.movingSeconds
        distance_meters = ride.distanceMeters
        average_speed_kmh = ride.averageSpeedKmh
        max_speed_kmh = ride.maxSpeedKmh
        start_lat = ride.startCoordinate?.latitude
        start_lng = ride.startCoordinate?.longitude
        end_lat = ride.endCoordinate?.latitude
        end_lng = ride.endCoordinate?.longitude
        weather_snapshot = ride.weatherSnapshot
        air_quality_snapshot = ride.airQualitySnapshot
        memo = ride.memo.isEmpty ? nil : ride.memo
        share_card_url = nil
        sync_status = ride.syncStatus.rawValue
    }
}

private struct SupabaseRidePointPayload: Encodable {
    let id: UUID
    let ride_id: UUID
    let recorded_at: Date
    let lat: Double
    let lng: Double
    let altitude: Double?
    let speed_mps: Double?
    let horizontal_accuracy: Double?
    let sequence: Int

    init(point: RidePoint) {
        id = point.id
        ride_id = point.rideID
        recorded_at = point.recordedAt
        lat = point.coordinate.latitude
        lng = point.coordinate.longitude
        altitude = point.altitude
        speed_mps = point.speedMps
        horizontal_accuracy = point.horizontalAccuracy
        sequence = point.sequence
    }
}
