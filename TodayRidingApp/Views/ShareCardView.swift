import SwiftUI
import TodayRidingCore

struct ShareCardView: View {
    @StateObject private var viewModel: ShareCardViewModel
    let onClose: () -> Void

    init(summary: RideSummary, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ShareCardViewModel(summary: summary))
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            card
                .aspectRatio(9 / 16, contentMode: .fit)
                .padding(.horizontal, 24)

            HStack(spacing: 14) {
                shareAction(icon: "photo", title: "사진 저장")
                shareAction(icon: "message.fill", title: "메시지")
                shareAction(icon: "square.and.arrow.up", title: "더보기")
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 18)
        .background(AppTheme.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("공유 카드")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            Button(action: {}) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 12)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoutePreview(points: viewModel.summary.points)
                .frame(height: 230)

            Text(AppFormatters.date(viewModel.summary.ride.startedAt))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.brand)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(AppFormatters.distanceKm(viewModel.summary.ride.distanceMeters))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("km")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Text(viewModel.summary.ride.title ?? "오늘 라이딩")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)

            Divider().overlay(AppTheme.hairline)

            HStack {
                cardStat(AppFormatters.duration(viewModel.summary.ride.durationSeconds), "시간")
                cardStat("\(AppFormatters.speedKmh(viewModel.summary.ride.averageSpeedKmh)) km/h", "평균")
                cardStat("\(AppFormatters.speedKmh(viewModel.summary.ride.maxSpeedKmh)) km/h", "최고")
            }

            Text(cardSummaryText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "bicycle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(AppTheme.brand, in: RoundedRectangle(cornerRadius: 7))
                Text("오늘탈까")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x1B2430), Color(hex: 0x0C1118)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26)
        )
    }

    private var cardSummaryText: String {
        let weather = viewModel.summary.ride.weatherSnapshot.map { "\(Int($0.temperatureCelsius))도 \($0.skyCondition)" } ?? "날씨 기록 없음"
        let air = viewModel.summary.ride.airQualitySnapshot.map { "PM2.5 \($0.pm25)" } ?? "미세먼지 기록 없음"
        let memo = viewModel.summary.ride.memo.isEmpty ? "" : " · \(viewModel.summary.ride.memo)"
        return "\(weather) · \(air)\(memo)"
    }

    private func cardStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func shareAction(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(AppTheme.surface2, in: RoundedRectangle(cornerRadius: 16))

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

