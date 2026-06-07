import Combine
import Foundation
import TodayRidingCore

@MainActor
final class RideHistoryViewModel: ObservableObject {
    @Published private(set) var rides: [Ride] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let localStore: LocalRideStore

    init(localStore: LocalRideStore) {
        self.localStore = localStore
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            rides = try await localStore.loadRides()
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
}

