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

