import Foundation

/// 저장된 라이딩 목록에서 월간/연간/전체 통계와 개인 기록, 연속 라이딩을 계산한다.
///
/// 종료된(`endedAt != nil`) 라이딩만 집계 대상으로 삼는다.
public enum RideStatisticsCalculator {
    public static func report(
        for rides: [Ride],
        calendar: Calendar = .korean,
        now: Date = Date()
    ) -> RideReport {
        let completed = rides.filter { $0.endedAt != nil }
        guard !completed.isEmpty else { return .empty }

        return RideReport(
            overall: periodStats(for: completed),
            years: yearlyReports(for: completed, calendar: calendar),
            records: personalRecords(for: completed),
            streak: streak(for: completed, calendar: calendar, now: now)
        )
    }

    public static func periodStats(for rides: [Ride]) -> PeriodStats {
        guard !rides.isEmpty else { return .empty }

        let totalDistance = rides.reduce(0) { $0 + $1.distanceMeters }
        let totalDuration = rides.reduce(0) { $0 + $1.durationSeconds }
        let totalMoving = rides.reduce(0) { $0 + $1.movingSeconds }

        return PeriodStats(
            rideCount: rides.count,
            totalDistanceMeters: totalDistance,
            totalDurationSeconds: totalDuration,
            totalMovingSeconds: totalMoving,
            averageSpeedKmh: SpeedFormatter.kmh(meters: totalDistance, seconds: totalMoving),
            maxSpeedKmh: rides.map(\.maxSpeedKmh).max() ?? 0,
            longestRideDistanceMeters: rides.map(\.distanceMeters).max() ?? 0
        )
    }

    public static func personalRecords(for rides: [Ride]) -> PersonalRecords {
        guard !rides.isEmpty else { return .empty }

        return PersonalRecords(
            longestDistanceMeters: rides.map(\.distanceMeters).max() ?? 0,
            longestDurationSeconds: rides.map(\.durationSeconds).max() ?? 0,
            topSpeedKmh: rides.map(\.maxSpeedKmh).max() ?? 0,
            bestAverageSpeedKmh: rides.map(\.averageSpeedKmh).max() ?? 0
        )
    }

    public static func yearlyReports(for rides: [Ride], calendar: Calendar = .korean) -> [YearlyReport] {
        let byYear = Dictionary(grouping: rides) { calendar.component(.year, from: $0.startedAt) }

        return byYear
            .map { year, yearRides in
                let byMonth = Dictionary(grouping: yearRides) { calendar.component(.month, from: $0.startedAt) }
                let months = byMonth
                    .map { month, monthRides in
                        MonthlyReport(year: year, month: month, stats: periodStats(for: monthRides))
                    }
                    .sorted { $0.month > $1.month }

                return YearlyReport(year: year, stats: periodStats(for: yearRides), months: months)
            }
            .sorted { $0.year > $1.year }
    }

    public static func streak(for rides: [Ride], calendar: Calendar = .korean, now: Date = Date()) -> RidingStreak {
        guard !rides.isEmpty else { return .empty }

        let rideDays = Set(rides.map { calendar.startOfDay(for: $0.startedAt) })
        let sortedDays = rideDays.sorted()

        // 가장 긴 연속 구간
        var longest = 1
        var run = 1
        for index in 1..<max(sortedDays.count, 1) {
            let previous = sortedDays[index - 1]
            let current = sortedDays[index]
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previous), nextDay == current {
                run += 1
                longest = max(longest, run)
            } else {
                run = 1
            }
        }
        if sortedDays.count == 1 { longest = 1 }

        // 현재 연속 구간 (오늘 또는 어제 기준 역산)
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)

        var anchor: Date?
        if rideDays.contains(today) {
            anchor = today
        } else if let yesterday, rideDays.contains(yesterday) {
            anchor = yesterday
        }

        var current = 0
        if var day = anchor {
            while rideDays.contains(day) {
                current += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
                day = previous
            }
        }

        return RidingStreak(currentDays: current, longestDays: longest)
    }
}

public extension Calendar {
    /// 한국 표준시(Asia/Seoul) 기준 그레고리력. 날짜/월/연 그룹핑 기준.
    static var korean: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        if let kst = TimeZone(identifier: "Asia/Seoul") {
            calendar.timeZone = kst
        }
        return calendar
    }
}
