import XCTest
@testable import TodayRidingCore

final class RideStatisticsTests: XCTestCase {
    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func ride(
        start: Date,
        distance: Double = 10_000,
        duration: Int = 1_800,
        moving: Int = 1_800,
        maxSpeed: Double = 30,
        avg: Double = 20,
        completed: Bool = true
    ) -> Ride {
        Ride(
            startedAt: start,
            endedAt: completed ? start.addingTimeInterval(Double(duration)) : nil,
            durationSeconds: duration,
            movingSeconds: moving,
            distanceMeters: distance,
            averageSpeedKmh: avg,
            maxSpeedKmh: maxSpeed
        )
    }

    func testEmptyRidesProduceEmptyReport() {
        let report = RideStatisticsCalculator.report(for: [], calendar: utc, now: date(2023, 11, 14))
        XCTAssertEqual(report, .empty)
    }

    func testIgnoresUnfinishedRides() {
        let rides = [ride(start: date(2023, 11, 14), completed: false)]
        let report = RideStatisticsCalculator.report(for: rides, calendar: utc, now: date(2023, 11, 14))
        XCTAssertEqual(report.overall.rideCount, 0)
    }

    func testOverallTotalsAndAverage() {
        let rides = [
            ride(start: date(2023, 11, 14), distance: 10_000, duration: 1_800, moving: 1_800),
            ride(start: date(2023, 11, 10), distance: 20_000, duration: 3_600, moving: 3_600)
        ]
        let report = RideStatisticsCalculator.report(for: rides, calendar: utc, now: date(2023, 11, 14))

        XCTAssertEqual(report.overall.rideCount, 2)
        XCTAssertEqual(report.overall.totalDistanceMeters, 30_000)
        XCTAssertEqual(report.overall.totalMovingSeconds, 5_400)
        // 30000m / 5400s * 3.6 = 20.0 km/h
        XCTAssertEqual(report.overall.averageSpeedKmh, 20.0, accuracy: 0.001)
        XCTAssertEqual(report.overall.longestRideDistanceMeters, 20_000)
    }

    func testYearlyAndMonthlyGrouping() {
        let rides = [
            ride(start: date(2023, 11, 14)),
            ride(start: date(2023, 10, 10)),
            ride(start: date(2022, 5, 5))
        ]
        let report = RideStatisticsCalculator.report(for: rides, calendar: utc, now: date(2023, 11, 14))

        XCTAssertEqual(report.years.map(\.year), [2023, 2022])
        XCTAssertEqual(report.years[0].stats.rideCount, 2)
        XCTAssertEqual(report.years[0].months.map(\.month), [11, 10])
        XCTAssertEqual(report.years[1].months.map(\.month), [5])
    }

    func testPersonalRecords() {
        let rides = [
            ride(start: date(2023, 11, 14), distance: 10_000, duration: 1_800, maxSpeed: 35, avg: 22),
            ride(start: date(2023, 11, 10), distance: 42_000, duration: 7_200, maxSpeed: 48, avg: 19)
        ]
        let records = RideStatisticsCalculator.personalRecords(for: rides)

        XCTAssertEqual(records.longestDistanceMeters, 42_000)
        XCTAssertEqual(records.longestDurationSeconds, 7_200)
        XCTAssertEqual(records.topSpeedKmh, 48)
        XCTAssertEqual(records.bestAverageSpeedKmh, 22)
    }

    func testCurrentStreakIncludesToday() {
        let now = date(2023, 11, 14)
        let rides = [
            ride(start: date(2023, 11, 14)),
            ride(start: date(2023, 11, 13)),
            ride(start: date(2023, 11, 12))
        ]
        let streak = RideStatisticsCalculator.streak(for: rides, calendar: utc, now: now)
        XCTAssertEqual(streak.currentDays, 3)
        XCTAssertEqual(streak.longestDays, 3)
    }

    func testCurrentStreakAnchorsToYesterdayWhenNoRideToday() {
        let now = date(2023, 11, 14)
        let rides = [
            ride(start: date(2023, 11, 13)),
            ride(start: date(2023, 11, 12))
        ]
        let streak = RideStatisticsCalculator.streak(for: rides, calendar: utc, now: now)
        XCTAssertEqual(streak.currentDays, 2)
    }

    func testLongestStreakWithGap() {
        let now = date(2023, 11, 14)
        let rides = [
            ride(start: date(2023, 11, 14)),
            ride(start: date(2023, 11, 13)),
            ride(start: date(2023, 11, 12)),
            ride(start: date(2023, 11, 1)) // 고립된 날
        ]
        let streak = RideStatisticsCalculator.streak(for: rides, calendar: utc, now: now)
        XCTAssertEqual(streak.longestDays, 3)
        XCTAssertEqual(streak.currentDays, 3)
    }

    func testStreakResetsWhenTodayAndYesterdayMissing() {
        let now = date(2023, 11, 14)
        let rides = [ride(start: date(2023, 11, 10))]
        let streak = RideStatisticsCalculator.streak(for: rides, calendar: utc, now: now)
        XCTAssertEqual(streak.currentDays, 0)
        XCTAssertEqual(streak.longestDays, 1)
    }
}
