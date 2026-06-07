import SwiftUI
import TodayRidingCore

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    let onStartRide: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if let recommendation = viewModel.recommendation,
                   let weather = viewModel.weather,
                   let airQuality = viewModel.airQuality {
                    scoreHeader(recommendation)
                    messageRow(recommendation.message)
                    metricGrid(weather: weather, airQuality: airQuality)
                    sunsetRow(weather)
                } else {
                    ProgressView()
                        .tint(AppTheme.brand)
                        .frame(maxWidth: .infinity, minHeight: 260)
                }

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "라이딩 시작", icon: "bicycle", action: onStartRide)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppTheme.background.opacity(0.92))
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.load()
        }
    }

    private var header: some View {
        HStack {
            Label(viewModel.weather?.locationName ?? "현재 위치", systemImage: "location.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .labelStyle(.titleAndIcon)
                .tint(AppTheme.brand)

            Spacer()

            Text(AppFormatters.date(Date()))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private func scoreHeader(_ recommendation: RidingRecommendation) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text("\(recommendation.score)")
                .font(.system(size: 92, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)

            VStack(alignment: .leading, spacing: 8) {
                Text(recommendation.grade.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color(for: recommendation.grade))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(color(for: recommendation.grade).opacity(0.18), in: Capsule())

                Text("적합도 / 100점")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()
        }
    }

    private func messageRow(_ message: String) -> some View {
        Label(message, systemImage: "clock.fill")
            .font(.system(size: 14.5, weight: .semibold))
            .foregroundStyle(AppTheme.ok)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func metricGrid(weather: WeatherSnapshot, airQuality: AirQualitySnapshot) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MetricChip(
                icon: "thermometer.medium",
                title: "기온",
                value: String(format: "%.0f", weather.temperatureCelsius),
                unit: "도"
            )
            MetricChip(
                icon: "wind",
                title: "바람",
                value: String(format: "%.1f", weather.windSpeedMps),
                unit: "m/s"
            )
            MetricChip(
                icon: "cloud.rain.fill",
                title: "강수",
                value: "\(weather.precipitationProbabilityPercent)",
                unit: "%"
            )
            MetricChip(
                icon: "aqi.medium",
                title: "초미세",
                value: "\(airQuality.pm25)",
                unit: "PM2.5"
            )
            MetricChip(
                icon: "humidity.fill",
                title: "습도",
                value: "\(weather.humidityPercent)",
                unit: "%"
            )
            MetricChip(
                icon: "sun.max.fill",
                title: "하늘",
                value: weather.skyCondition,
                unit: weather.precipitationType.label
            )
        }
    }

    private func sunsetRow(_ weather: WeatherSnapshot) -> some View {
        Label("일몰 \(AppFormatters.time(weather.sunsetAt)) · 야간 라이트 권장", systemImage: "sunset.fill")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.textTertiary)
            .tint(AppTheme.ok)
    }

    private func color(for grade: RidingScoreGrade) -> Color {
        switch grade {
        case .excellent, .good:
            return AppTheme.good
        case .caution, .shortOnly:
            return AppTheme.ok
        case .notRecommended:
            return AppTheme.bad
        }
    }
}

