import Foundation

public struct RidingCoachAdvice: Sendable, Equatable {
    public enum Tone: String, Sendable, Equatable {
        case encouraging
        case reassuring
        case cautious
        case recoveryReminder
    }

    public let headline: String
    public let detail: String
    public let tone: Tone

    public init(headline: String, detail: String, tone: Tone) {
        self.headline = headline
        self.detail = detail
        self.tone = tone
    }
}

public enum RidingCoach {
    public static func advice(
        rides: [Ride],
        recommendation: RidingRecommendation?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> RidingCoachAdvice {
        let lastSevenDays = recentRides(rides, days: 7, now: now, calendar: calendar)
        let lastThirtyDays = recentRides(rides, days: 30, now: now, calendar: calendar)
        let mostRecentRide = rides.max(by: { $0.startedAt < $1.startedAt })

        // Long absence overrides everything.
        if let last = mostRecentRide,
           let days = calendar.dateComponents([.day], from: last.startedAt, to: now).day,
           days >= 30 {
            return RidingCoachAdvice(
                headline: "한 달 만의 라이딩이에요",
                detail: "오랜만이니 10km 내외로 가볍게 컨디션부터 점검해보세요.",
                tone: .reassuring
            )
        }

        // Too much volume in the last week.
        if lastSevenDays.count >= 4 {
            return RidingCoachAdvice(
                headline: "이번 주 잘 타고 있어요",
                detail: "회복을 위해 오늘은 짧게 타거나 쉬는 것도 좋아요.",
                tone: .recoveryReminder
            )
        }

        // No rides yet this week.
        if mostRecentRide != nil, lastSevenDays.isEmpty {
            return RidingCoachAdvice(
                headline: "이번 주 아직 라이딩이 없어요",
                detail: "짧게라도 한 번 다녀오면 다음 라이딩이 더 편해집니다.",
                tone: .encouraging
            )
        }

        // First-ever ride hint.
        if rides.isEmpty {
            return RidingCoachAdvice(
                headline: "첫 라이딩을 기다리고 있어요",
                detail: "오늘 컨디션이 괜찮다면 5km 짧은 코스부터 시작해보세요.",
                tone: .encouraging
            )
        }

        // Lean on the daily recommendation score for the fallback message.
        if let recommendation {
            switch recommendation.grade {
            case .excellent, .good:
                return RidingCoachAdvice(
                    headline: "오늘 컨디션 좋아요",
                    detail: averageDistanceHint(rides: lastThirtyDays, fallback: "익숙한 코스로 평소보다 5km 더 타보세요.") ?? "익숙한 코스로 평소보다 5km 더 타보세요.",
                    tone: .encouraging
                )
            case .caution:
                return RidingCoachAdvice(
                    headline: "주의가 필요한 날",
                    detail: recommendation.warnings.first ?? "짧게 다녀오는 것을 추천합니다.",
                    tone: .cautious
                )
            case .shortOnly:
                return RidingCoachAdvice(
                    headline: "짧게 다녀오기 좋은 날",
                    detail: recommendation.warnings.first ?? "10km 내외의 가벼운 코스가 좋겠어요.",
                    tone: .cautious
                )
            case .notRecommended:
                return RidingCoachAdvice(
                    headline: "오늘은 쉬는 게 좋아요",
                    detail: recommendation.warnings.first ?? "실내 트레이닝이나 스트레칭을 추천합니다.",
                    tone: .cautious
                )
            }
        }

        return RidingCoachAdvice(
            headline: "꾸준히 잘 타고 있어요",
            detail: "지난 30일 \(lastThirtyDays.count)회 라이딩. 페이스를 유지해보세요.",
            tone: .reassuring
        )
    }

    private static func recentRides(_ rides: [Ride], days: Int, now: Date, calendar: Calendar) -> [Ride] {
        guard let threshold = calendar.date(byAdding: .day, value: -days, to: now) else {
            return []
        }
        return rides.filter { $0.startedAt >= threshold && $0.startedAt <= now }
    }

    private static func averageDistanceHint(rides: [Ride], fallback: String) -> String? {
        guard !rides.isEmpty else { return nil }
        let avgKm = rides.reduce(0.0) { $0 + $1.distanceMeters } / Double(rides.count) / 1_000
        guard avgKm > 0.5 else { return nil }
        return String(format: "지난 30일 평균 %.1fkm. 오늘도 비슷한 거리 어떠세요?", avgKm)
    }
}
