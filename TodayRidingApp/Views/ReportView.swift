import SwiftUI
import TodayRidingCore

struct ReportView: View {
    @StateObject private var viewModel: ReportViewModel
    let onClose: () -> Void

    init(localStore: LocalRideStore, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(localStore: localStore))
        self.onClose = onClose
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if viewModel.isLoading {
                    ProgressView()
                        .tint(AppTheme.brand)
                        .frame(maxWidth: .infinity, minHeight: 240)
                } else if !viewModel.hasData {
                    emptyState
                } else {
                    overallCard
                    streakCard
                    recordsCard

                    ForEach(viewModel.report.years) { year in
                        yearSection(year)
                    }

                    if !viewModel.suggestedCourses.isEmpty {
                        suggestionsSection
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.load()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("리포트")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text("누적 \(viewModel.report.overall.rideCount)회 · \(AppFormatters.distanceKm(viewModel.report.overall.totalDistanceMeters)) km")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppTheme.brand)
            Text("아직 집계할 라이딩이 없습니다.")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text("라이딩을 완료하면 월간·연간 통계가 쌓입니다.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(20)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var overallCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StatBlock(
                    value: AppFormatters.distanceKm(viewModel.report.overall.totalDistanceMeters),
                    unit: "km",
                    label: "총 거리",
                    accent: AppTheme.brand
                )
                Divider().overlay(AppTheme.hairline)
                StatBlock(
                    value: "\(viewModel.report.overall.rideCount)",
                    unit: "회",
                    label: "라이딩"
                )
            }
            Divider().overlay(AppTheme.hairline)
            HStack(spacing: 0) {
                StatBlock(
                    value: AppFormatters.duration(viewModel.report.overall.totalDurationSeconds),
                    unit: "",
                    label: "총 시간"
                )
                Divider().overlay(AppTheme.hairline)
                StatBlock(
                    value: AppFormatters.speedKmh(viewModel.report.overall.averageSpeedKmh),
                    unit: "km/h",
                    label: "평균 속도"
                )
            }
        }
        .padding(.vertical, 16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var streakCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.brand)

            VStack(alignment: .leading, spacing: 3) {
                Text("현재 \(viewModel.report.streak.currentDays)일 연속")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Text("최장 연속 \(viewModel.report.streak.longestDays)일")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("개인 기록")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textTertiary)

            recordRow(icon: "ruler.fill", label: "최장 거리", value: "\(AppFormatters.distanceKm(viewModel.report.records.longestDistanceMeters)) km")
            recordRow(icon: "clock.fill", label: "최장 시간", value: AppFormatters.duration(viewModel.report.records.longestDurationSeconds))
            recordRow(icon: "speedometer", label: "최고 속도", value: "\(AppFormatters.speedKmh(viewModel.report.records.topSpeedKmh)) km/h")
            recordRow(icon: "gauge.medium", label: "최고 평속", value: "\(AppFormatters.speedKmh(viewModel.report.records.bestAverageSpeedKmh)) km/h")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private func recordRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private func yearSection(_ year: YearlyReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(String(year.year))년")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(year.stats.rideCount)회 · \(AppFormatters.distanceKm(year.stats.totalDistanceMeters)) km")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            VStack(spacing: 8) {
                ForEach(year.months) { month in
                    monthRow(month)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("다시 타기 좋은 코스")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)

            ForEach(viewModel.suggestedCourses) { suggestion in
                suggestionRow(suggestion)
            }
        }
    }

    private func suggestionRow(_ suggestion: SuggestedCourse) -> some View {
        HStack(spacing: 12) {
            Image(systemName: suggestionIcon(for: suggestion.reason))
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.brand)
                .frame(width: 32, height: 32)
                .background(AppTheme.brand.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(suggestion.reason.label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.brand)
                Text(suggestion.ride.title ?? "오늘 라이딩")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(suggestion.detail)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)
            }
            Spacer()
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func suggestionIcon(for reason: SuggestedCourse.Reason) -> String {
        switch reason {
        case .longest: return "arrow.up.right.circle.fill"
        case .mostRecent: return "clock.fill"
        case .fastest: return "speedometer"
        case .mostRepeated: return "repeat.circle.fill"
        }
    }

    private func monthRow(_ month: MonthlyReport) -> some View {
        HStack(spacing: 12) {
            Text("\(month.month)월")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, alignment: .leading)

            Text("\(month.stats.rideCount)회")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)

            Spacer()

            Text("\(AppFormatters.distanceKm(month.stats.totalDistanceMeters)) km · \(AppFormatters.speedKmh(month.stats.averageSpeedKmh)) km/h")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(AppTheme.surface2, in: RoundedRectangle(cornerRadius: 12))
    }
}
