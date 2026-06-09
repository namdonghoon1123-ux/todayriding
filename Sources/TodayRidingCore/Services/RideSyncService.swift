import Foundation

public protocol SupabaseService: Sendable {
    func uploadRide(_ ride: Ride, points: [RidePoint]) async throws
}

public struct NoopSupabaseService: SupabaseService {
    public init() {}

    public func uploadRide(_ ride: Ride, points: [RidePoint]) async throws {
        _ = ride
        _ = points
        throw SupabaseUploadError.notConfigured
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

    /// 로컬에 저장된 `pending` / `failed` / `localOnly` 라이딩을 일괄 재동기화하고 결과 요약을 돌려준다.
    /// 호출자(예: 앱 실행 시 RootView)는 결과를 토스트나 로그로 노출할 수 있다.
    public func resyncAllPending(localStore: LocalRideStore) async -> RideResyncSummary {
        var summary = RideResyncSummary()
        let pendingRides: [Ride]
        do {
            pendingRides = try await localStore.loadPendingRides()
        } catch {
            return summary
        }

        for var ride in pendingRides {
            let points = (try? await localStore.loadPoints(for: ride.id)) ?? []
            let newStatus = await sync(ride: ride, points: points)
            ride.syncStatus = newStatus
            try? await localStore.saveRide(ride)
            summary.record(status: newStatus)
        }

        return summary
    }
}

/// `resyncAllPending`의 실행 결과 카운트.
public struct RideResyncSummary: Sendable, Equatable {
    public var succeeded = 0
    public var stillPending = 0
    public var failed = 0

    public init() {}

    public var attempted: Int {
        succeeded + stillPending + failed
    }

    mutating func record(status: RideSyncStatus) {
        switch status {
        case .synced:
            succeeded += 1
        case .pending, .localOnly:
            stillPending += 1
        case .failed:
            failed += 1
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

/// 인증된 라이딩 업로더. `accessTokenProvider`가 제공한 JWT를 Bearer 헤더로 사용한다.
/// 토큰이 nil이면 anon 키 그대로 사용(=현재 RLS에서 거부됨, 의도적).
public struct HTTPSupabaseService: SupabaseService {
    public typealias TokenProvider = @Sendable () async -> String?
    public typealias UserIDProvider = @Sendable () async -> UUID?

    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let accessTokenProvider: TokenProvider
    private let userIDProvider: UserIDProvider

    public init(
        configuration: SupabaseConfiguration,
        session: URLSession = .shared,
        accessTokenProvider: @escaping TokenProvider = { nil },
        userIDProvider: @escaping UserIDProvider = { nil }
    ) {
        self.configuration = configuration
        self.session = session
        self.accessTokenProvider = accessTokenProvider
        self.userIDProvider = userIDProvider

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    public func uploadRide(_ ride: Ride, points: [RidePoint]) async throws {
        let currentUserID = await userIDProvider()
        let effectiveUserID = ride.userID ?? currentUserID
        guard let effectiveUserID else {
            throw SupabaseUploadError.notConfigured
        }

        try await post(
            path: "rides",
            body: SupabaseRidePayload(ride: ride, userID: effectiveUserID)
        )

        if !points.isEmpty {
            try await post(
                path: "ride_points",
                body: points.map { SupabaseRidePointPayload(point: $0, userID: effectiveUserID) }
            )
        }
    }

    private func post<T: Encodable>(path: String, body: T) async throws {
        let url = configuration.projectURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")

        let bearer = await accessTokenProvider() ?? configuration.anonKey
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        request.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
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
    case notConfigured
    case requestFailed
}

private struct SupabaseRidePayload: Encodable {
    let id: UUID
    let user_id: UUID
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

    init(ride: Ride, userID: UUID) {
        id = ride.id
        user_id = userID
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
    let user_id: UUID
    let recorded_at: Date
    let lat: Double
    let lng: Double
    let altitude: Double?
    let speed_mps: Double?
    let horizontal_accuracy: Double?
    let sequence: Int

    init(point: RidePoint, userID: UUID) {
        id = point.id
        ride_id = point.rideID
        user_id = userID
        recorded_at = point.recordedAt
        lat = point.coordinate.latitude
        lng = point.coordinate.longitude
        altitude = point.altitude
        speed_mps = point.speedMps
        horizontal_accuracy = point.horizontalAccuracy
        sequence = point.sequence
    }
}
