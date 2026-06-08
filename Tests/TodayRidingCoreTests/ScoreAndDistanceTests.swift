import XCTest
@testable import TodayRidingCore

final class DistanceCalculatorTests: XCTestCase {
    func testSinglePointIsZero() {
        let point = GeoPoint(latitude: 37.5445, longitude: 127.0557)
        XCTAssertEqual(DistanceCalculator.totalDistanceMeters([point]), 0)
    }

    func testAccumulatedDistance() {
        let points = [
            GeoPoint(latitude: 37.5445, longitude: 127.0557),
            GeoPoint(latitude: 37.5450, longitude: 127.0560),
            GeoPoint(latitude: 37.5455, longitude: 127.0563)
        ]
        let distance = DistanceCalculator.totalDistanceMeters(points)
        XCTAssertGreaterThan(distance, 100)
        XCTAssertLessThan(distance, 140)
    }
}

final class RidingScoreCalculatorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)

    private func weather(
        temperature: Double,
        feelsLike: Double,
        humidity: Int,
        precipProbability: Int,
        precipType: PrecipitationType,
        windSpeed: Double,
        sunsetOffsetHours: Double
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            observedAt: now,
            locationName: "서울",
            temperatureCelsius: temperature,
            feelsLikeCelsius: feelsLike,
            humidityPercent: humidity,
            precipitationProbabilityPercent: precipProbability,
            precipitationType: precipType,
            skyCondition: "맑음",
            cloudDescription: "구름 조금",
            windSpeedMps: windSpeed,
            windDirection: "서풍",
            sunsetAt: now.addingTimeInterval(sunsetOffsetHours * 3_600)
        )
    }

    func testClearConditionsScorePerfect() {
        let recommendation = RidingScoreCalculator.recommendation(
            weather: weather(
                temperature: 22, feelsLike: 22, humidity: 55,
                precipProbability: 10, precipType: .none, windSpeed: 2, sunsetOffsetHours: 4
            ),
            airQuality: AirQualitySnapshot(pm10: 20, pm25: 10, stationName: "성수", measuredAt: now),
            now: now
        )
        XCTAssertEqual(recommendation.score, 100)
        XCTAssertEqual(recommendation.grade, .excellent)
    }

    func testBadConditionsNotRecommended() {
        let recommendation = RidingScoreCalculator.recommendation(
            weather: weather(
                temperature: 31, feelsLike: 33, humidity: 82,
                precipProbability: 70, precipType: .rain, windSpeed: 8, sunsetOffsetHours: 1
            ),
            airQuality: AirQualitySnapshot(pm10: 80, pm25: 45, stationName: "성수", measuredAt: now),
            now: now
        )
        XCTAssertLessThan(recommendation.score, 40)
        XCTAssertEqual(recommendation.grade, .notRecommended)
    }

    func testHighPm25AddsWarning() {
        let recommendation = RidingScoreCalculator.recommendation(
            weather: weather(
                temperature: 22, feelsLike: 22, humidity: 55,
                precipProbability: 10, precipType: .none, windSpeed: 2, sunsetOffsetHours: 4
            ),
            airQuality: AirQualitySnapshot(pm10: 90, pm25: 50, stationName: "성수", measuredAt: now),
            now: now
        )
        XCTAssertTrue(recommendation.warnings.contains { $0.contains("초미세먼지") })
        XCTAssertLessThan(recommendation.score, 100)
    }
}
