import Combine
import Foundation
import TodayRidingCore

@MainActor
final class ShareCardViewModel: ObservableObject {
    let summary: RideSummary

    init(summary: RideSummary) {
        self.summary = summary
    }
}
