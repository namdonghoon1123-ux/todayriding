import Foundation

public struct SuggestedCourse: Sendable, Equatable, Identifiable {
    public enum Reason: String, Sendable, Equatable {
        case longest
        case mostRecent
        case fastest
        case mostRepeated

        public var label: String {
            switch self {
            case .longest: return "최장 거리"
            case .mostRecent: return "가장 최근"
            case .fastest: return "최고 평균 속도"
            case .mostRepeated: return "자주 다닌 코스"
            }
        }
    }

    public let ride: Ride
    public let reason: Reason
    public let detail: String

    public var id: String { "\(reason.rawValue)-\(ride.id.uuidString)" }

    public init(ride: Ride, reason: Reason, detail: String) {
        self.ride = ride
        self.reason = reason
        self.detail = detail
    }
}

public enum CourseSuggester {
    public static func suggest(from rides: [Ride], limit: Int = 3) -> [SuggestedCourse] {
        let candidates = rides.filter { $0.distanceMeters > 0 }
        guard !candidates.isEmpty else { return [] }

        var suggestions: [SuggestedCourse] = []
        var usedRideIDs: Set<UUID> = []

        if let longest = candidates.max(by: { $0.distanceMeters < $1.distanceMeters }) {
            suggestions.append(
                SuggestedCourse(
                    ride: longest,
                    reason: .longest,
                    detail: String(format: "%.1f km · %@", longest.distanceMeters / 1_000, durationText(seconds: longest.durationSeconds))
                )
            )
            usedRideIDs.insert(longest.id)
        }

        if let mostRecent = candidates
            .filter({ !usedRideIDs.contains($0.id) })
            .max(by: { $0.startedAt < $1.startedAt }) {
            suggestions.append(
                SuggestedCourse(
                    ride: mostRecent,
                    reason: .mostRecent,
                    detail: String(format: "%.1f km · %@", mostRecent.distanceMeters / 1_000, durationText(seconds: mostRecent.durationSeconds))
                )
            )
            usedRideIDs.insert(mostRecent.id)
        }

        if let fastest = candidates
            .filter({ !usedRideIDs.contains($0.id) && $0.averageSpeedKmh > 0 })
            .max(by: { $0.averageSpeedKmh < $1.averageSpeedKmh }) {
            suggestions.append(
                SuggestedCourse(
                    ride: fastest,
                    reason: .fastest,
                    detail: String(format: "평균 %.1f km/h · %.1f km", fastest.averageSpeedKmh, fastest.distanceMeters / 1_000)
                )
            )
            usedRideIDs.insert(fastest.id)
        }

        if suggestions.count < limit {
            if let repeatedStart = mostRepeatedStartingArea(rides: candidates),
               !usedRideIDs.contains(repeatedStart.ride.id) {
                suggestions.append(repeatedStart)
            }
        }

        return Array(suggestions.prefix(limit))
    }

    private static func durationText(seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        if hours > 0 {
            return "\(hours)시간 \(minutes)분"
        }
        return "\(minutes)분"
    }

    /// Cluster rides by ~1km starting-coordinate buckets and surface the bucket with the most repeats.
    private static func mostRepeatedStartingArea(rides: [Ride]) -> SuggestedCourse? {
        let bucketDegrees = 0.01 // ≈ 1.1km at Seoul latitude
        var buckets: [String: [Ride]] = [:]

        for ride in rides {
            guard let start = ride.startCoordinate else { continue }
            let key = String(
                format: "%.0f,%.0f",
                (start.latitude / bucketDegrees).rounded(),
                (start.longitude / bucketDegrees).rounded()
            )
            buckets[key, default: []].append(ride)
        }

        guard let largest = buckets.values
            .filter({ $0.count >= 2 })
            .max(by: { $0.count < $1.count }),
              let representative = largest.max(by: { $0.startedAt < $1.startedAt })
        else {
            return nil
        }

        return SuggestedCourse(
            ride: representative,
            reason: .mostRepeated,
            detail: String(format: "이 출발지에서 %d회 라이딩 · 마지막 %.1f km", largest.count, representative.distanceMeters / 1_000)
        )
    }
}
