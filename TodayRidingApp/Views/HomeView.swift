import SwiftUI
import TodayRidingCore

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @AppStorage(HealthKitWorkoutRecorder.isEnabledDefaultsKey)
    private var healthKitEnabled = false
    @State private var healthKitToast: String?
    let onStartRide: () -> Void
    let onShowHistory: () -> Void
    let onShowReport: () -> Void

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
                    if let advice = viewModel.coachAdvice {
                        coachCard(advice)
                    }
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
        .alert(
            "건강 앱",
            isPresented: Binding(
                get: { healthKitToast != nil },
                set: { isPresented in
                    if !isPresented { healthKitToast = nil }
                }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(healthKitToast ?? "")
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

            Button(action: toggleHealthKit) {
                Image(systemName: healthKitEnabled ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(healthKitEnabled ? AppTheme.bad : AppTheme.textTertiary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.surface2, in: Circle())
            }
            .accessibilityLabel(healthKitEnabled ? "건강 앱 저장 끄기" : "건강 앱 저장 켜기")

            Button(action: onShowReport) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.surface2, in: Circle())
            }
            .accessibilityLabel("리포트 보기")

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

    private func toggleHealthKit() {
        Task {
            if healthKitEnabled {
                HealthKitWorkoutRecorder.disable()
                healthKitToast = "건강 앱 저장을 껐습니다."
            } else {
                let granted = await HealthKitWorkoutRecorder.enable()
                healthKitToast = granted
                    ? "라이딩 종료 시 건강 앱에 사이클링 운동이 저장됩니다."
                    : "건강 앱 권한이 필요합니다. 설정에서 권한을 허용해주세요."
            }
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

    private func coachCard(_ advice: RidingCoachAdvice) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon(for: advice.tone))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(toneColor(for: advice.tone))
                .frame(width: 36, height: 36)
                .background(toneColor(for: advice.tone).opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(advice.headline)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text(advice.detail)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func icon(for tone: RidingCoachAdvice.Tone) -> String {
        switch tone {
        case .encouraging: return "bolt.heart.fill"
        case .reassuring: return "checkmark.seal.fill"
        case .cautious: return "exclamationmark.triangle.fill"
        case .recoveryReminder: return "bed.double.fill"
        }
    }

    private func toneColor(for tone: RidingCoachAdvice.Tone) -> Color {
        switch tone {
        case .encouraging: return AppTheme.brand
        case .reassuring: return AppTheme.good
        case .cautious: return AppTheme.ok
        case .recoveryReminder: return AppTheme.textSecondary
        }
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
