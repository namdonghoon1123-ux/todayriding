import XCTest
@testable import TodayRidingCore

final class RideSyncEdgeCaseTests: XCTestCase {
    func testNetworkOfflineErrorKeepsRidePending() async {
        let ride = Ride(startedAt: Date(timeIntervalSince1970: 4_000))
        let service = RideSyncService(
            supabaseService: ThrowingSupabaseService(error: URLError(.notConnectedToInternet))
        )
        let status = await service.sync(ride: ride, points: [])
        XCTAssertEqual(status, .pending)
    }

    func testTimeoutErrorKeepsRidePending() async {
        let ride = Ride(startedAt: Date(timeIntervalSince1970: 4_000))
        let service = RideSyncService(
            supabaseService: ThrowingSupabaseService(error: URLError(.timedOut))
        )
        let status = await service.sync(ride: ride, points: [])
        XCTAssertEqual(status, .pending)
    }

    func testServerErrorKeepsRidePending() async {
        let ride = Ride(startedAt: Date(timeIntervalSince1970: 4_000))
        let service = RideSyncService(
            supabaseService: ThrowingSupabaseService(error: SupabaseUploadError.requestFailed)
        )
        let status = await service.sync(ride: ride, points: [])
        XCTAssertEqual(status, .pending)
    }

    func testResyncAllPendingMarksAllSyncedWhenServerSucceeds() async throws {
        let store = InMemoryRideStore()
        let pendingRide = Ride(
            startedAt: Date(timeIntervalSince1970: 5_000),
            distanceMeters: 5_000,
            syncStatus: .pending
        )
        let failedRide = Ride(
            startedAt: Date(timeIntervalSince1970: 5_100),
            distanceMeters: 6_000,
            syncStatus: .failed
        )
        try await store.saveRide(pendingRide)
        try await store.saveRide(failedRide)

        let service = RideSyncService(supabaseService: AlwaysSucceedsSupabaseService())
        let summary = await service.resyncAllPending(localStore: store)

        XCTAssertEqual(summary.succeeded, 2)
        XCTAssertEqual(summary.stillPending, 0)
        XCTAssertEqual(summary.failed, 0)
        XCTAssertEqual(summary.attempted, 2)

        let storedRides = try await store.loadRides()
        let syncedCount = storedRides.filter { $0.syncStatus == .synced }.count
        XCTAssertEqual(syncedCount, 2)
    }

    func testResyncAllPendingKeepsRidesPendingWhenOffline() async throws {
        let store = InMemoryRideStore()
        let ride = Ride(
            startedAt: Date(timeIntervalSince1970: 5_000),
            distanceMeters: 5_000,
            syncStatus: .pending
        )
        try await store.saveRide(ride)

        let service = RideSyncService(
            supabaseService: ThrowingSupabaseService(error: URLError(.notConnectedToInternet))
        )
        let summary = await service.resyncAllPending(localStore: store)

        XCTAssertEqual(summary.stillPending, 1)
        XCTAssertEqual(summary.succeeded, 0)
        XCTAssertEqual(summary.failed, 0)
        XCTAssertEqual(summary.attempted, 1)
    }

    func testResyncAllPendingReturnsZeroWhenNothingPending() async {
        let store = InMemoryRideStore()
        let service = RideSyncService(supabaseService: AlwaysSucceedsSupabaseService())
        let summary = await service.resyncAllPending(localStore: store)
        XCTAssertEqual(summary.attempted, 0)
    }

    // MARK: - Helpers

    private struct ThrowingSupabaseService: SupabaseService {
        let error: Error
        func uploadRide(_ ride: Ride, points: [RidePoint]) async throws {
            throw error
        }
    }

    private struct AlwaysSucceedsSupabaseService: SupabaseService {
        func uploadRide(_ ride: Ride, points: [RidePoint]) async throws {}
    }
}
