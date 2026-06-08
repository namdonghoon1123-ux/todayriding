import Combine
import Foundation
import TodayRidingCore

@MainActor
final class RideHistoryViewModel: ObservableObject {
    @Published private(set) var rides: [Ride] = []
    @Published private(set) var pointsByRide: [UUID: [RidePoint]] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var syncingRideID: UUID?
    @Published private(set) var errorMessage: String?

    private let localStore: LocalRideStore
    private let syncService: RideSyncService?

    /// Supabase가 설정돼 있어 수동 재시도가 의미 있는지.
    var canSync: Bool { syncService != nil }

    init(
        localStore: LocalRideStore,
        syncService: RideSyncService? = AppSupabaseServiceFactory.make().map(RideSyncService.init)
    ) {
        self.localStore = localStore
        self.syncService = syncService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let loadedRides = try await localStore.loadRides()
            rides = loadedRides

            var map: [UUID: [RidePoint]] = [:]
            for ride in loadedRides {
                map[ride.id] = (try? await localStore.loadPoints(for: ride.id)) ?? []
            }
            pointsByRide = map
        } catch {
            errorMessage = "기록을 불러오지 못했습니다."
        }
    }

    func summary(for ride: Ride) async -> RideSummary? {
        do {
            let points = try await localStore.loadPoints(for: ride.id)
            return RideSummary(ride: ride, points: points)
        } catch {
            errorMessage = "라이딩 상세를 불러오지 못했습니다."
            return nil
        }
    }

    /// 동기화 실패/대기 항목을 Supabase로 다시 업로드한다.
    func retry(_ ride: Ride) async {
        guard let syncService else { return }

        syncingRideID = ride.id
        defer { syncingRideID = nil }

        let points = (try? await localStore.loadPoints(for: ride.id)) ?? []
        let status = await syncService.sync(ride: ride, points: points)

        var updated = ride
        updated.syncStatus = status
        try? await localStore.saveRide(updated)

        if let index = rides.firstIndex(where: { $0.id == ride.id }) {
            rides[index] = updated
        }

        if status != .synced {
            errorMessage = "동기화에 실패했습니다. 네트워크 상태를 확인해주세요."
        }
    }
}
