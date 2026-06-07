import Foundation

public enum RidingScoreCalculator {
    public static func recommendation(
        weather: WeatherSnapshot,
        airQuality: AirQualitySnapshot,
        now: Date = Date()
    ) -> RidingRecommendation {
        var score = 100
        var warnings: [String] = []

        if weather.precipitationProbabilityPercent >= 50 {
            score -= 28
            warnings.append("비 가능성 있어 장거리 비추천")
        }

        if airQuality.pm25Grade == .bad || airQuality.pm25Grade == .veryBad {
            score -= 25
            warnings.append("초미세먼지 나쁨, 실내 운동 추천")
        }

        if weather.windSpeedMps >= 7 {
            score -= 14
            warnings.append("복귀길 맞바람 주의")
        }

        if weather.temperatureCelsius >= 30 {
            score -= 12
            warnings.append("고온 주의")
        }

        if weather.humidityPercent >= 80 && weather.temperatureCelsius >= 27 {
            score -= 10
            warnings.append("높은 습도로 체감 피로 주의")
        }

        if weather.sunsetAt.timeIntervalSince(now) < 90 * 60 {
            score -= 8
            warnings.append("일몰 임박, 라이트 권장")
        }

        score = max(0, min(100, score))
        let grade = grade(for: score)
        let message = message(for: score, warnings: warnings)

        return RidingRecommendation(
            score: score,
            grade: grade,
            message: message,
            warnings: warnings
        )
    }

    public static func grade(for score: Int) -> RidingScoreGrade {
        switch score {
        case 90...:
            return .excellent
        case 75..<90:
            return .good
        case 60..<75:
            return .caution
        case 40..<60:
            return .shortOnly
        default:
            return .notRecommended
        }
    }

    private static func message(for score: Int, warnings: [String]) -> String {
        if let firstWarning = warnings.first, score < 75 {
            return firstWarning
        }

        switch grade(for: score) {
        case .excellent:
            return "오늘 18:00~20:30 라이딩 추천"
        case .good:
            return "짧게 30km 이하 추천"
        case .caution:
            return warnings.first ?? "가능하지만 컨디션 확인 필요"
        case .shortOnly:
            return warnings.first ?? "짧은 라이딩만 추천"
        case .notRecommended:
            return warnings.first ?? "오늘은 실내 운동 추천"
        }
    }
}

