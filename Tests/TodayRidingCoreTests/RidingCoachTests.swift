import XCTest
@testable import TodayRidingCore

final class RidingCoachTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        return c
    }

    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testEmptyHistoryGivesEncouragingTone() {
        let advice = RidingCoach.advice(rides: [], recommendation: nil, now: now, calendar: calendar)
        XCTAssertEqual(advice.tone, .encouraging)
        XCTAssertFalse(advice.headline.isEmpty)
        XCTAssertFalse(advice.detail.isEmpty)
    }

    func testLongAbsenceGivesReassuringTone() {
        let oneAndHalfMonthAgo = now.addingTimeInterval(-60 * 60 * 24 * 45)
        let ride = Ride(startedAt: oneAndHalfMonthAgo, distanceMeters: 10_000)

        let advice = RidingCoach.advice(rides: [ride], recommendation: nil, now: now, calendar: calendar)
        XCTAssertEqual(advice.tone, .reassuring)
    }

    func testOvertrainingGivesRecoveryReminder() {
        let week = (0..<4).map { offset in
            Ride(
                startedAt: now.addingTimeInterval(-Double(offset) * 60 * 60 * 24),
                distanceMeters: 8_000
            )
        }
        let advice = RidingCoach.advice(rides: week, recommendation: nil, now: now, calendar: calendar)
        XCTAssertEqual(advice.tone, .recoveryReminder)
    }

    func testEmptyWeekAfterPriorRidesIsEncouraging() {
        let twoWeeksAgo = now.addingTimeInterval(-60 * 60 * 24 * 14)
        let ride = Ride(startedAt: twoWeeksAgo, distanceMeters: 10_000)

        let advice = RidingCoach.advice(rides: [ride], recommendation: nil, now: now, calendar: calendar)
        XCTAssertEqual(advice.tone, .encouraging)
    }

    func testNotRecommendedGradeProducesCautiousAdvice() {
        let ride = Ride(startedAt: now.addingTimeInterval(-3 * 60 * 60 * 24), distanceMeters: 10_000)
        let recommendation = RidingRecommendation(
            score: 20,
            grade: .notRecommended,
            message: "오늘은 라이딩 비추천",
            warnings: ["비 가능성 매우 높음"]
        )

        let advice = RidingCoach.advice(rides: [ride], recommendation: recommendation, now: now, calendar: calendar)
        XCTAssertEqual(advice.tone, .cautious)
    }
}
