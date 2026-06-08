import SwiftUI
import TodayRidingCore

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var presentedDetail: MetricDetail?
    let onStartRide: () -> Void
    let onShowHistory: () -> Void
    let onShowReport: () -> Void
    var onShowCourses: (() -> Void)? = nil
    var onSignOut: (() -> Void)? = nil

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
        .sheet(item: $presentedDetail) { detail in
            MetricDetailSheet(detail: detail)
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

            if let onShowCourses {
                Button(action: onShowCourses) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.brand)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.surface2, in: Circle())
                }
                .accessibilityLabel("코스 짜기")
            }

            Button(action: onShowReport) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.surface2, in: Circle())
            }
            .accessibilityLabel("리포트 보기")

            if let onSignOut {
                Button(action: onSignOut) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.surface2, in: Circle())
                }
                .accessibilityLabel("로그아웃")
            }

            Button(action: onShowHistory) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.surface2, in: Circle())
            }
            .accessibilityLabel("기록 보기")

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
            metricButton(detail: MetricDetail.temperature(weather)) {
                MetricChip(icon: "thermometer.medium", title: "기온",
                           value: String(format: "%.0f", weather.temperatureCelsius), unit: "도")
            }
            metricButton(detail: MetricDetail.wind(weather)) {
                MetricChip(icon: "wind", title: "바람",
                           value: String(format: "%.1f", weather.windSpeedMps), unit: "m/s")
            }
            metricButton(detail: MetricDetail.precipitation(weather)) {
                MetricChip(icon: "cloud.rain.fill", title: "강수",
                           value: "\(weather.precipitationProbabilityPercent)", unit: "%")
            }
            metricButton(detail: MetricDetail.pm25(airQuality)) {
                MetricChip(icon: "aqi.medium", title: "초미세",
                           value: "\(airQuality.pm25)", unit: "PM2.5")
            }
            metricButton(detail: MetricDetail.humidity(weather)) {
                MetricChip(icon: "humidity.fill", title: "습도",
                           value: "\(weather.humidityPercent)", unit: "%")
            }
            metricButton(detail: MetricDetail.sky(weather)) {
                MetricChip(icon: "sun.max.fill", title: "하늘",
                           value: weather.skyCondition, unit: weather.precipitationType.label)
            }
            if let uv = viewModel.uvIndex {
                metricButton(detail: MetricDetail.uvIndex(uv)) {
                    MetricChip(icon: "sun.max.trianglebadge.exclamationmark.fill",
                               title: "자외선", value: "\(uv.value)", unit: uv.category.label)
                }
            }
            metricButton(detail: MetricDetail.sunset(weather)) {
                MetricChip(icon: "sunset.fill", title: "일몰",
                           value: AppFormatters.time(weather.sunsetAt), unit: "KST")
            }
        }
    }

    private func metricButton<Content: View>(detail: MetricDetail, @ViewBuilder content: () -> Content) -> some View {
        Button {
            presentedDetail = detail
        } label: {
            content()
        }
        .buttonStyle(.plain)
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
