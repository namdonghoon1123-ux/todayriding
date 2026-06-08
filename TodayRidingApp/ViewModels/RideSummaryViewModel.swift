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

    /// 현재 라이딩을 GPX 파일로 임시 디렉터리에 쓰고 공유용 URL을 돌려준다.
    func exportGPXFile() -> URL? {
        guard !summary.points.isEmpty else { return nil }

        let gpx = GPXExporter.gpx(for: summary.ride, points: summary.points)
        let fileName = "todayriding-\(summary.ride.id.uuidString).gpx"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try gpx.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
