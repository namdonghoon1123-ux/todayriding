import XCTest
@testable import TodayRidingCore

final class RainAlertEvaluatorTests: XCTestCase {
    private func weather(prob: Int, type: PrecipitationType) -> WeatherSnapshot {
        let now = Date(timeIntervalSince1970: 1_000)
        return WeatherSnapshot(
            observedAt: now,
            locationName: "서울",
            temperatureCelsius: 22,
            feelsLikeCelsius: 22,
            humidityPercent: 55,
            precipitationProbabilityPercent: prob,
            precipitationType: type,
            skyCondition: "흐림",
            cloudDescription: "구름 많음",
            windSpeedMps: 2,
            windDirection: "서풍",
            sunsetAt: now.addingTimeInterval(4 * 3_600)
        )
    }

    func testRainImminentByPrecipitationType() {
        XCTAssertTrue(RainAlertEvaluator.isRainImminent(weather(prob: 10, type: .rain)))
        XCTAssertTrue(RainAlertEvaluator.isRainImminent(weather(prob: 0, type: .shower)))
    }

    func testRainImminentByProbabilityThreshold() {
        XCTAssertTrue(RainAlertEvaluator.isRainImminent(weather(prob: 60, type: .none)))
        XCTAssertFalse(RainAlertEvaluator.isRainImminent(weather(prob: 59, type: .none)))
    }

    func testWarnsOnFirstEvaluationWhenRisky() {
        XCTAssertTrue(RainAlertEvaluator.shouldWarn(previous: nil, current: weather(prob: 70, type: .none)))
        XCTAssertFalse(RainAlertEvaluator.shouldWarn(previous: nil, current: weather(prob: 20, type: .none)))
    }

    func testWarnsOnlyOnTransitionToRisk() {
        let safe = weather(prob: 20, type: .none)
        let risky = weather(prob: 80, type: .rain)

        // 안전 -> 위험: 경고
        XCTAssertTrue(RainAlertEvaluator.shouldWarn(previous: safe, current: risky))
        // 위험 -> 위험: 중복 경고 안 함
        XCTAssertFalse(RainAlertEvaluator.shouldWarn(previous: risky, current: risky))
        // 위험 -> 안전: 경고 안 함
        XCTAssertFalse(RainAlertEvaluator.shouldWarn(previous: risky, current: safe))
    }

    func testWarningMessage() {
        XCTAssertTrue(RainAlertEvaluator.warningMessage(for: weather(prob: 80, type: .rain)).contains("비"))
        XCTAssertTrue(RainAlertEvaluator.warningMessage(for: weather(prob: 75, type: .none)).contains("75%"))
    }
}
