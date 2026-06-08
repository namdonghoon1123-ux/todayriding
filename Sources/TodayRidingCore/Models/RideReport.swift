import Foundation

/// 한 기간(전체/연/월)의 라이딩 집계 통계.
public struct PeriodStats: Equatable, Sendable {
    public let rideCount: Int
    public let totalDistanceMeters: Double
    public let totalDurationSeconds: Int
    public let totalMovingSeconds: Int
    public let averageSpeedKmh: Double
    public let maxSpeedKmh: Double
    public let longestRideDistanceMeters: Double

    public init(
        rideCount: Int,
        totalDistanceMeters: Double,
        totalDurationSeconds: Int,
        totalMovingSeconds: Int,
        averageSpeedKmh: Double,
        maxSpeedKmh: Double,
        longestRideDistanceMeters: Double
    ) {
        self.rideCount = rideCount
        self.totalDistanceMeters = totalDistanceMeters
        self.totalDurationSeconds = totalDurationSeconds
        self.totalMovingSeconds = totalMovingSeconds
        self.averageSpeedKmh = averageSpeedKmh
        self.maxSpeedKmh = maxSpeedKmh
        self.longestRideDistanceMeters = longestRideDistanceMeters
    }

    public static let empty = PeriodStats(
        rideCount: 0,
        totalDistanceMeters: 0,
        totalDurationSeconds: 0,
        totalMovingSeconds: 0,
        averageSpeedKmh: 0,
        maxSpeedKmh: 0,
        longestRideDistanceMeters: 0
    )
}

public struct MonthlyReport: Equatable, Sendable, Identifiable {
    public let year: Int
    public let month: Int
    public let stats: PeriodStats

    public var id: String { "\(year)-\(month)" }

    public init(year: Int, month: Int, stats: PeriodStats) {
        self.year = year
        self.month = month
        self.stats = stats
    }
}

public struct YearlyReport: Equatable, Sendable, Identifiable {
    public let year: Int
    public let stats: PeriodStats
    public let months: [MonthlyReport]

    public var id: Int { year }

    public init(year: Int, stats: PeriodStats, months: [MonthlyReport]) {
        self.year = year
        self.stats = stats
        self.months = months
    }
}

/// 개인 최고 기록.
public struct PersonalRecords: Equatable, Sendable {
    public let longestDistanceMeters: Double
    public let longestDurationSeconds: Int
    public let topSpeedKmh: Double
    public let bestAverageSpeedKmh: Double

    public init(
        longestDistanceMeters: Double,
        longestDurationSeconds: Int,
        topSpeedKmh: Double,
        bestAverageSpeedKmh: Double
    ) {
        self.longestDistanceMeters = longestDistanceMeters
        self.longestDurationSeconds = longestDurationSeconds
        self.topSpeedKmh = topSpeedKmh
        self.bestAverageSpeedKmh = bestAverageSpeedKmh
    }

    public static let empty = PersonalRecords(
        longestDistanceMeters: 0,
        longestDurationSeconds: 0,
        topSpeedKmh: 0,
        bestAverageSpeedKmh: 0
    )
}

/// 연속 라이딩 일수.
public struct RidingStreak: Equatable, Sendable {
    public let currentDays: Int
    public let longestDays: Int

    public init(currentDays: Int, longestDays: Int) {
        self.currentDays = currentDays
        self.longestDays = longestDays
    }

    public static let empty = RidingStreak(currentDays: 0, longestDays: 0)
}

/// 전체 라이딩 리포트.
public struct RideReport: Equatable, Sendable {
    public let overall: PeriodStats
    public let years: [YearlyReport]
    public let records: PersonalRecords
    public let streak: RidingStreak

    public init(
        overall: PeriodStats,
        years: [YearlyReport],
        records: PersonalRecords,
        streak: RidingStreak
    ) {
        self.overall = overall
        self.years = years
        self.records = records
        self.streak = streak
    }

    public static let empty = RideReport(
        overall: .empty,
        years: [],
        records: .empty,
        streak: .empty
    )
}
