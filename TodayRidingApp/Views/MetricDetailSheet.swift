import SwiftUI
import TodayRidingCore

struct MetricDetail: Identifiable {
    enum Kind: String, Identifiable {
        case temperature, wind, precipitation, pm25, humidity, sky, uvIndex, sunset
        var id: String { rawValue }
    }

    let id = UUID()
    let kind: Kind
    let title: String
    let valueText: String
    let unit: String
    let icon: String
    let tintHex: UInt
    let description: String
    let guidance: [String]
}

extension MetricDetail {
    static func temperature(_ weather: WeatherSnapshot) -> MetricDetail {
        let feels = Int(weather.feelsLikeCelsius)
        return MetricDetail(
            kind: .temperature,
            title: "기온",
            valueText: String(format: "%.0f", weather.temperatureCelsius),
            unit: "°C",
            icon: "thermometer.medium",
            tintHex: 0xFFB663,
            description: "현재 외기 온도. 체감 \(feels)°C.",
            guidance: [
                "0–10°C: 방한 자켓 + 장갑 필수",
                "10–18°C: 긴팔 저지 권장",
                "18–25°C: 라이딩 최적",
                "25–30°C: 수분 자주 보충",
                "30°C+: 짧게 + 그늘 코스, 정오 피하기"
            ]
        )
    }

    static func wind(_ weather: WeatherSnapshot) -> MetricDetail {
        MetricDetail(
            kind: .wind,
            title: "바람",
            valueText: String(format: "%.1f", weather.windSpeedMps),
            unit: "m/s",
            icon: "wind",
            tintHex: 0x6FB1FF,
            description: "현재 풍속 (방향: \(weather.windDirection)).",
            guidance: [
                "0–3 m/s: 무풍-약풍",
                "3–6 m/s: 평지 무난",
                "6–9 m/s: 복귀길 맞바람 주의",
                "9 m/s+: 장거리 비추천"
            ]
        )
    }

    static func precipitation(_ weather: WeatherSnapshot) -> MetricDetail {
        MetricDetail(
            kind: .precipitation,
            title: "강수확률",
            valueText: "\(weather.precipitationProbabilityPercent)",
            unit: "%",
            icon: "cloud.rain.fill",
            tintHex: 0x4A9EFF,
            description: "현재 시점 강수확률. 형태: \(weather.precipitationType.label)",
            guidance: [
                "0–30%: 그대로 라이딩",
                "30–50%: 가벼운 우의 챙기기",
                "50–70%: 짧은 코스만 추천",
                "70%+: 실내 운동 추천"
            ]
        )
    }

    static func pm25(_ airQuality: AirQualitySnapshot) -> MetricDetail {
        let gradeLabel: String
        switch airQuality.pm25Grade {
        case .good: gradeLabel = "좋음"
        case .normal: gradeLabel = "보통"
        case .bad: gradeLabel = "나쁨"
        case .veryBad: gradeLabel = "매우 나쁨"
        }
        return MetricDetail(
            kind: .pm25,
            title: "초미세먼지 PM2.5",
            valueText: "\(airQuality.pm25)",
            unit: "μg/m³",
            icon: "aqi.medium",
            tintHex: 0xFF8A65,
            description: "\(airQuality.stationName) 측정소 · \(gradeLabel)",
            guidance: [
                "0–15: 좋음, 자유롭게",
                "16–35: 보통, 평소대로",
                "36–75: 나쁨, 마스크 + 짧은 코스",
                "76+: 매우 나쁨, 실내 운동 추천"
            ]
        )
    }

    static func humidity(_ weather: WeatherSnapshot) -> MetricDetail {
        MetricDetail(
            kind: .humidity,
            title: "습도",
            valueText: "\(weather.humidityPercent)",
            unit: "%",
            icon: "humidity.fill",
            tintHex: 0x66D9C2,
            description: "현재 상대 습도. 높을수록 체감 더위 증가.",
            guidance: [
                "30–60%: 쾌적",
                "60–75%: 약간 끈적함",
                "75%+: 고온 + 습도 → 열사병 주의"
            ]
        )
    }

    static func sky(_ weather: WeatherSnapshot) -> MetricDetail {
        MetricDetail(
            kind: .sky,
            title: "하늘 상태",
            valueText: weather.skyCondition,
            unit: weather.cloudDescription,
            icon: "sun.max.fill",
            tintHex: 0xFFC857,
            description: "구름 양과 하늘 상태.",
            guidance: [
                "맑음: 자외선 차단제 + 선글라스",
                "구름 조금/많음: 선글라스 권장",
                "흐림: 야간 가시성 라이트 권장"
            ]
        )
    }

    static func uvIndex(_ uv: UVIndexSnapshot) -> MetricDetail {
        MetricDetail(
            kind: .uvIndex,
            title: "자외선 지수 UV",
            valueText: "\(uv.value)",
            unit: uv.category.label,
            icon: "sun.max.trianglebadge.exclamationmark.fill",
            tintHex: 0xFFA94D,
            description: "현재 시각 기준 자외선 강도. 출처: \(uv.source).",
            guidance: [
                "0–2 (낮음): 별도 조치 불필요",
                "3–5 (보통): 선글라스 권장",
                "6–7 (높음): 자외선 차단제 + 모자",
                "8–10 (매우 높음): 정오 라이딩 피하기",
                "11+ (위험): 야외 활동 최소화"
            ]
        )
    }

    static func sunset(_ weather: WeatherSnapshot) -> MetricDetail {
        MetricDetail(
            kind: .sunset,
            title: "일몰",
            valueText: AppFormatters.time(weather.sunsetAt),
            unit: "KST",
            icon: "sunset.fill",
            tintHex: 0xFF8A57,
            description: "오늘 일몰 시각. 라이딩 종료 시점 가이드.",
            guidance: [
                "일몰 30분 전: 후미등 점등",
                "일몰 ~ 일몰 후 60분: 전조등 필수",
                "일몰 후 90분+: 야간 라이딩 — 가시성 코스 권장"
            ]
        )
    }
}

struct MetricDetailSheet: View {
    let detail: MetricDetail
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Text(detail.description)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
                    Text("가이드")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                    ForEach(detail.guidance, id: \.self) { line in
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Circle()
                                .fill(Color(hex: detail.tintHex))
                                .frame(width: 6, height: 6)
                            Text(line)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))

                Spacer(minLength: 20)
            }
            .padding(20)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: detail.icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: detail.tintHex))
                .frame(width: 52, height: 52)
                .background(Color(hex: detail.tintHex).opacity(0.18), in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 4) {
                Text(detail.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(detail.valueText)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(detail.unit)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
    }
}
