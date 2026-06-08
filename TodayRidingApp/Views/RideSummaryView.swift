import SwiftUI
import TodayRidingCore

struct RideSummaryView: View {
    @StateObject private var viewModel: RideSummaryViewModel
    @State private var gpxURL: URL?
    let onShare: (RideSummary) -> Void
    let onDone: () -> Void

    init(summary: RideSummary, onShare: @escaping (RideSummary) -> Void, onDone: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: RideSummaryViewModel(summary: summary))
        self.onShare = onShare
        self.onDone = onDone
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                RoutePreview(points: viewModel.summary.points)
                    .frame(height: 220)

                statsGrid

                weatherSummary

                memoEditor

                Spacer(minLength: 90)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "공유 카드 만들기", icon: "square.and.arrow.up") {
                onShare(viewModel.updatedSummary())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(AppTheme.background.opacity(0.92))
        }
        .toolbar {
            if let gpxURL {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: gpxURL) {
                        Image(systemName: "square.and.arrow.up.on.square")
                            .foregroundStyle(AppTheme.brand)
                    }
                    .accessibilityLabel("GPX 내보내기")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("완료", action: onDone)
                    .foregroundStyle(AppTheme.brand)
            }
        }
        .task {
            gpxURL = viewModel.exportGPXFile()
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘탔다")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.brand)
            Text(viewModel.summary.ride.title ?? "오늘 라이딩")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
            Text(AppFormatters.date(viewModel.summary.ride.startedAt))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var statsGrid: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StatBlock(
                    value: AppFormatters.distanceKm(viewModel.summary.ride.distanceMeters),
                    unit: "km",
                    label: "거리"
                )
                Divider().overlay(AppTheme.hairline)
                StatBlock(
                    value: AppFormatters.duration(viewModel.summary.ride.durationSeconds),
                    unit: "",
                    label: "시간"
                )
            }
            Divider().overlay(AppTheme.hairline)
            HStack(spacing: 0) {
                StatBlock(
                    value: AppFormatters.speedKmh(viewModel.summary.ride.averageSpeedKmh),
                    unit: "km/h",
                    label: "평균"
                )
                Divider().overlay(AppTheme.hairline)
                StatBlock(
                    value: AppFormatters.speedKmh(viewModel.summary.ride.maxSpeedKmh),
                    unit: "km/h",
                    label: "최고"
                )
            }
        }
        .padding(.vertical, 16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var weatherSummary: some View {
        HStack(spacing: 10) {
            if let weather = viewModel.summary.ride.weatherSnapshot {
                Label("\(Int(weather.temperatureCelsius))도 · \(weather.skyCondition)", systemImage: "sun.max.fill")
                    .summaryChip()
            }

            if let airQuality = viewModel.summary.ride.airQualitySnapshot {
                Label("PM2.5 \(airQuality.pm25)", systemImage: "aqi.medium")
                    .summaryChip()
            }
        }
    }

    private var memoEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("한 줄 메모", systemImage: "pencil")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)

            TextField("오늘 라이딩 느낌을 남겨보세요", text: $viewModel.memo, axis: .vertical)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(3, reservesSpace: true)
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}

private extension View {
    func summaryChip() -> some View {
        font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppTheme.surface2, in: Capsule())
    }
}

