import Combine
import Foundation
import TodayRidingCore

@MainActor
final class ReportViewModel: ObservableObject {
    @Published private(set) var report: RideReport = .empty
    @Published private(set) var suggestedCourses: [SuggestedCourse] = []
    @Published private(set) var isLoading = false

    private let localStore: LocalRideStore

    init(localStore: LocalRideStore) {
        self.localStore = localStore
    }

    var hasData: Bool { report.overall.rideCount > 0 }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let rides = (try? await localStore.loadRides()) ?? []
        report = RideStatisticsCalculator.report(for: rides)
        suggestedCourses = CourseSuggester.suggest(from: rides)
    }
}
