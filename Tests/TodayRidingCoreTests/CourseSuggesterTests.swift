import XCTest
@testable import TodayRidingCore

final class CourseSuggesterTests: XCTestCase {
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let seoulStart = GeoPoint(latitude: 37.5445, longitude: 127.0557)

    func testEmptyInputProducesNoSuggestions() {
        XCTAssertTrue(CourseSuggester.suggest(from: []).isEmpty)
    }

    func testIgnoresZeroDistanceRides() {
        let zero = Ride(
            startedAt: baseDate,
            distanceMeters: 0,
            averageSpeedKmh: 0,
            startCoordinate: seoulStart
        )
        XCTAssertTrue(CourseSuggester.suggest(from: [zero]).isEmpty)
    }

    func testPicksLongestMostRecentAndFastest() {
        let shortRide = Ride(
            startedAt: baseDate,
            durationSeconds: 600,
            distanceMeters: 5_000,
            averageSpeedKmh: 12,
            startCoordinate: seoulStart
        )
        let longRide = Ride(
            startedAt: baseDate.addingTimeInterval(60 * 60 * 24),
            durationSeconds: 3_600,
            distanceMeters: 30_000,
            averageSpeedKmh: 20,
            startCoordinate: seoulStart
        )
        let fastRide = Ride(
            startedAt: baseDate.addingTimeInterval(60 * 60 * 24 * 2),
            durationSeconds: 1_800,
            distanceMeters: 12_000,
            averageSpeedKmh: 28,
            startCoordinate: seoulStart
        )

        let suggestions = CourseSuggester.suggest(from: [shortRide, longRide, fastRide])

        XCTAssertTrue(suggestions.contains { $0.reason == .longest && $0.ride.id == longRide.id })
        XCTAssertTrue(suggestions.contains { $0.reason == .mostRecent && $0.ride.id == fastRide.id })
        XCTAssertTrue(suggestions.contains { $0.reason == .fastest })
    }

    func testRespectsLimitParameter() {
        var rides: [Ride] = []
        for offset in 0..<5 {
            let startedAt = baseDate.addingTimeInterval(Double(offset) * 86_400)
            let distance = Double(5_000 + offset * 1_000)
            let speed = Double(15 + offset)
            rides.append(
                Ride(
                    startedAt: startedAt,
                    durationSeconds: 1_800,
                    distanceMeters: distance,
                    averageSpeedKmh: speed,
                    startCoordinate: seoulStart
                )
            )
        }
        let suggestions = CourseSuggester.suggest(from: rides, limit: 2)
        XCTAssertLessThanOrEqual(suggestions.count, 2)
    }

    func testIdentifiesMostRepeatedStartingArea() {
        // 같은 출발지(약 1km 버킷)에서 3회 + 다른 출발지 1회
        var popularRides: [Ride] = []
        for offset in 0..<3 {
            let startedAt = baseDate.addingTimeInterval(Double(offset) * 86_400)
            let distance = Double(7_000 + offset * 500)
            popularRides.append(
                Ride(
                    startedAt: startedAt,
                    durationSeconds: 1_500,
                    distanceMeters: distance,
                    averageSpeedKmh: 18,
                    startCoordinate: seoulStart
                )
            )
        }
        let outlierStart = GeoPoint(latitude: 35.0, longitude: 129.0)
        let outlier = Ride(
            startedAt: baseDate.addingTimeInterval(86_400 * 10),
            durationSeconds: 3_600,
            distanceMeters: 50_000,
            averageSpeedKmh: 25,
            startCoordinate: outlierStart
        )

        let suggestions = CourseSuggester.suggest(from: popularRides + [outlier], limit: 4)
        if let repeated = suggestions.first(where: { $0.reason == .mostRepeated }) {
            XCTAssertEqual(repeated.ride.startCoordinate?.latitude ?? 0, seoulStart.latitude, accuracy: 0.01)
        }
    }
}
