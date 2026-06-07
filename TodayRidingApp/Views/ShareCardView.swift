import SwiftUI
import TodayRidingCore
import UIKit

struct ShareCardView: View {
    @StateObject private var viewModel: ShareCardViewModel
    @State private var isShowingShareSheet = false
    @State private var statusMessage: String?
    let onClose: () -> Void

    init(summary: RideSummary, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ShareCardViewModel(summary: summary))
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            ShareCardContent(summary: viewModel.summary)
                .aspectRatio(9 / 16, contentMode: .fit)
                .padding(.horizontal, 24)

            HStack(spacing: 14) {
                shareAction(icon: "photo", title: "사진 저장") {
                    statusMessage = viewModel.saveRenderedImageToPhotos()
                }
                shareAction(icon: "message.fill", title: "메시지") {
                    viewModel.renderCardImage()
                    isShowingShareSheet = viewModel.renderedImage != nil
                }
                shareAction(icon: "square.and.arrow.up", title: "더보기") {
                    viewModel.renderCardImage()
                    isShowingShareSheet = viewModel.renderedImage != nil
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 18)
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            viewModel.renderCardImage()
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let image = viewModel.renderedImage {
                ActivityView(activityItems: [image])
            }
        }
        .alert(
            "오늘탈까",
            isPresented: Binding(
                get: { statusMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        statusMessage = nil
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(statusMessage ?? "")
        }
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

            Button {
                statusMessage = viewModel.saveRenderedImageToPhotos()
            } label: {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.brand)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 12)
    }

    private func shareAction(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
    }
}

struct ShareCardContent: View {
    let summary: RideSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoutePreview(points: summary.points)
                .frame(height: 230)

            Text(AppFormatters.date(summary.ride.startedAt))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.brand)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(AppFormatters.distanceKm(summary.ride.distanceMeters))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("km")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Text(summary.ride.title ?? "오늘 라이딩")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)

            Divider().overlay(AppTheme.hairline)

            HStack {
                cardStat(AppFormatters.duration(summary.ride.durationSeconds), "시간")
                cardStat("\(AppFormatters.speedKmh(summary.ride.averageSpeedKmh)) km/h", "평균")
                cardStat("\(AppFormatters.speedKmh(summary.ride.maxSpeedKmh)) km/h", "최고")
            }

            Text(summaryText)
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

    private var summaryText: String {
        let weather = summary.ride.weatherSnapshot.map { "\(Int($0.temperatureCelsius))도 \($0.skyCondition)" } ?? "날씨 기록 없음"
        let air = summary.ride.airQualitySnapshot.map { "PM2.5 \($0.pm25)" } ?? "미세먼지 기록 없음"
        let memo = summary.ride.memo.isEmpty ? "" : " · \(summary.ride.memo)"
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
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        _ = uiViewController
        _ = context
    }
}
