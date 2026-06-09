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
        VStack(spacing: 0) {
            header
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 16) {
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
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        ZStack {
            // 인스타 스토리 비율 (9:16) 배경 그라데이션
            LinearGradient(
                colors: [
                    Color(hex: 0xFF6B35),
                    Color(hex: 0x1B2430),
                    Color(hex: 0x0B0F14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 도트 패턴 오버레이 (라이딩 무드)
            GeometryReader { proxy in
                Canvas { context, size in
                    let spacing: CGFloat = 24
                    for x in stride(from: 0, through: size.width, by: spacing) {
                        for y in stride(from: 0, through: size.height, by: spacing) {
                            let rect = CGRect(x: x, y: y, width: 1.5, height: 1.5)
                            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.07)))
                        }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }

            VStack(alignment: .leading, spacing: 20) {
                // 상단 로고 + 날짜
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "bicycle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(AppTheme.brand, in: RoundedRectangle(cornerRadius: 8))
                        Text("오늘탔다")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text(AppFormatters.date(summary.ride.startedAt))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.12), in: Capsule())
                }

                // 경로 미리보기
                RoutePreview(points: summary.points)
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                    )

                // 메인 거리
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(AppFormatters.distanceKm(summary.ride.distanceMeters))
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
                        Text("km")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Text(summary.ride.title ?? "오늘 라이딩")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                // 핵심 stats
                HStack(spacing: 0) {
                    cardStat(AppFormatters.duration(summary.ride.durationSeconds), "시간")
                    Divider().frame(width: 1).overlay(.white.opacity(0.16))
                    cardStat("\(AppFormatters.speedKmh(summary.ride.averageSpeedKmh)) km/h", "평균")
                    Divider().frame(width: 1).overlay(.white.opacity(0.16))
                    cardStat("\(AppFormatters.speedKmh(summary.ride.maxSpeedKmh)) km/h", "최고")
                }
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    .white.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )

                // 날씨 칩
                HStack(spacing: 8) {
                    if let weather = summary.ride.weatherSnapshot {
                        infoChip(icon: "sun.max.fill", text: "\(Int(weather.temperatureCelsius))° \(weather.skyCondition)")
                    }
                    if let airQuality = summary.ride.airQualitySnapshot {
                        infoChip(icon: "aqi.medium", text: "PM2.5 \(airQuality.pm25)")
                    }
                }

                if !summary.ride.memo.isEmpty {
                    Text("\u{201C}\(summary.ride.memo)\u{201D}")
                        .font(.system(size: 13, weight: .semibold))
                        .italic()
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(3)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }

                Spacer()

                // 하단 브랜드 워터마크
                HStack(spacing: 6) {
                    Text("오늘탈까")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 3, height: 3)
                    Text("Today Riding")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                    Spacer()
                }
            }
            .padding(28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private func cardStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
    }

    private func infoChip(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12.5, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.white.opacity(0.13), in: Capsule())
            .overlay(
                Capsule().stroke(.white.opacity(0.15), lineWidth: 1)
            )
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
