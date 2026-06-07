import Combine
import Foundation
import TodayRidingCore

@MainActor
final class RideSummaryViewModel: ObservableObject {
    @Published var memo: String
    @Published private(set) var summary: RideSummary

    init(summary: RideSummary) {
        self.summary = summary
        self.memo = summary.ride.memo
    }

    func updatedSummary() -> RideSummary {
        var ride = summary.ride
        ride.memo = memo
        return RideSummary(ride: ride, points: summary.points)
    }
}
