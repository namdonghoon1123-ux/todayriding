import Foundation

/// 라이딩 중 강수(비구름) 접근 경고 판단.
///
/// 날씨 스냅샷의 강수형태/강수확률로 위험 여부를 판단하고,
/// 직전 평가 대비 새롭게 위험이 생겼을 때만 경고하도록 해 중복 알림을 막는다.
public enum RainAlertEvaluator {
    public static let defaultProbabilityThreshold = 60

    /// 현재 강수 위험 여부. 강수형태가 있거나 강수확률이 임계치 이상이면 위험.
    public static func isRainImminent(
        _ weather: WeatherSnapshot,
        probabilityThreshold: Int = defaultProbabilityThreshold
    ) -> Bool {
        if weather.precipitationType != .none {
            return true
        }
        return weather.precipitationProbabilityPercent >= probabilityThreshold
    }

    /// 직전 대비 새롭게 위험이 생겼는가. 첫 평가(previous == nil)에서 위험이면 경고한다.
    public static func shouldWarn(
        previous: WeatherSnapshot?,
        current: WeatherSnapshot,
        probabilityThreshold: Int = defaultProbabilityThreshold
    ) -> Bool {
        guard isRainImminent(current, probabilityThreshold: probabilityThreshold) else {
            return false
        }
        guard let previous else {
            return true
        }
        // 이전에 이미 위험했다면 다시 경고하지 않는다.
        return !isRainImminent(previous, probabilityThreshold: probabilityThreshold)
    }

    public static func warningMessage(for weather: WeatherSnapshot) -> String {
        if weather.precipitationType != .none {
            return "\(weather.precipitationType.label) 소식이 있어요. 안전한 복귀를 준비하세요."
        }
        return "강수확률 \(weather.precipitationProbabilityPercent)% — 비구름이 다가오고 있어요."
    }
}
