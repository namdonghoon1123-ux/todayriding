import XCTest
@testable import TodayRidingCore

final class RideTrackerTests: XCTestCase {
    func testAccumulatesDistanceDurationAndSpeed() {
        let clock = ManualClock(now: Date(timeIntervalSince1970: 1_000))
        let tracker = RideTracker(clock: { clock.now })

        let ride = tracker.start(weather: nil, airQuality: nil)
        XCTAssertEqual(ride.distanceMeters, 0)

        _ = tracker.appendLocation(
            coordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557),
            speedMps: 5,
            horizontalAccuracy: 8
        )

        clock.now = Date(timeIntervalSince1970: 1_060)
        let updated = tracker.appendLocation(
            coordinate: GeoPoint(latitude: 37.5450, longitude: 127.0560),
            speedMps: 6,
            horizontalAccuracy: 8
        )

        XCTAssertGreaterThan(updated?.distanceMeters ?? 0, 50)
        XCTAssertEqual(updated?.durationSeconds, 60)
        XCTAssertEqual(updated?.maxSpeedKmh, 21.6)
    }

    func testFinishMarksPending() {
        let clock = ManualClock(now: Date(timeIntervalSince1970: 1_000))
        let tracker = RideTracker(clock: { clock.now })
        _ = tracker.start(weather: nil, airQuality: nil)

        clock.now = Date(timeIntervalSince1970: 1_120)
        let finished = tracker.finish()

        XCTAssertEqual(finished?.syncStatus, .pending)
        XCTAssertNotNil(finished?.endedAt)
    }

    func testPausedTrackerIgnoresLocations() {
        let tracker = RideTracker()
        _ = tracker.start(weather: nil, airQuality: nil)
        tracker.pause()

        _ = tracker.appendLocation(
            coordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557),
            speedMps: 5,
            horizontalAccuracy: 8
        )

        XCTAssertTrue(tracker.points.isEmpty)
    }

    final class ManualClock: @unchecked Sendable {
        var now: Date
        init(now: Date) { self.now = now }
    }
}

final class FileRideStoreTests: XCTestCase {
    func testPersistsRidesAndPoints() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("todayriding-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FileRideStore(directoryURL: directory)
        let ride = Ride(
            startedAt: Date(timeIntervalSince1970: 2_000),
            distanceMeters: 1234,
            syncStatus: .pending
        )
        let point = RidePoint(
            rideID: ride.id,
            recordedAt: ride.startedAt,
            coordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557),
            sequence: 0
        )

        try await store.saveRide(ride)
        try await store.appendPoint(point)

        let allRides = try await store.loadRides()
        let pendingRides = try await store.loadPendingRides()
        let points = try await store.loadPoints(for: ride.id)

        XCTAssertTrue(allRides.map(\.id).contains(ride.id))
        XCTAssertTrue(pendingRides.map(\.id).contains(ride.id))
        XCTAssertEqual(points, [point])
    }

    func testSyncedRideNotPending() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("todayriding-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FileRideStore(directoryURL: directory)
        let ride = Ride(startedAt: Date(timeIntervalSince1970: 3_000), syncStatus: .synced)
        try await store.saveRide(ride)

        let pendingRides = try await store.loadPendingRides()
        XCTAssertFalse(pendingRides.map(\.id).contains(ride.id))
    }
}

final class RideSyncServiceTests: XCTestCase {
    func testUnconfiguredSyncStaysPending() async {
        let ride = Ride(startedAt: Date(timeIntervalSince1970: 3_000))
        let service = RideSyncService(supabaseService: NoopSupabaseService())
        let status = await service.sync(ride: ride, points: [])
        XCTAssertEqual(status, .pending)
    }

    func testSuccessfulSyncReportsSynced() async {
        let ride = Ride(startedAt: Date(timeIntervalSince1970: 3_000))
        let service = RideSyncService(supabaseService: AlwaysSucceedsSupabaseService())
        let status = await service.sync(ride: ride, points: [])
        XCTAssertEqual(status, .synced)
    }

    private struct AlwaysSucceedsSupabaseService: SupabaseService {
        func uploadRide(_ ride: Ride, points: [RidePoint]) async throws {}
    }
}
