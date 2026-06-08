import SwiftUI
import TodayRidingCore

struct RideTrackingView: View {
    @ObservedObject var viewModel: RideTrackingViewModel
    @StateObject private var locationManager = LocationManager()
    let onFinish: (RideSummary) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                RoutePreview(points: viewModel.points)
                    .frame(maxWidth: .infinity)
                    .frame(height: 360)
                    .ignoresSafeArea(edges: .top)

                recordingPill
                    .padding(.top, 14)
            }

            VStack(spacing: 22) {
                Capsule()
                    .fill(AppTheme.hairline)
                    .frame(width: 40, height: 4)

                distanceHero

                Divider()
                    .overlay(AppTheme.hairline)

                HStack {
                    StatBlock(
                        value: AppFormatters.duration(viewModel.ride.durationSeconds),
                        unit: "",
                        label: "시간"
                    )
                    StatBlock(
                        value: AppFormatters.speedKmh(currentSpeedKmh),
                        unit: "km/h",
                        label: "현재",
                        accent: AppTheme.brand
                    )
                    StatBlock(
                        value: AppFormatters.speedKmh(viewModel.ride.averageSpeedKmh),
                        unit: "km/h",
                        label: "평균"
                    )
                }

                HStack(spacing: 18) {
                    Button {
                        viewModel.requestPauseOrResume()
                    } label: {
                        Image(systemName: viewModel.trackingState == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 70)
                            .background(AppTheme.surface2, in: Circle())
                    }

                    Button {
                        Task {
                            onFinish(await viewModel.finish())
                        }
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 84, height: 84)
                            .background(AppTheme.bad, in: Circle())
                            .shadow(color: AppTheme.bad.opacity(0.38), radius: 12, y: 8)
                    }

                    Button {
                        viewModel.addMockPoint()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 70, height: 70)
                            .background(AppTheme.surface2, in: Circle())
                    }
                    .accessibilityLabel("Mock 위치 추가")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity)
            .background(AppTheme.background)
            .clipShape(.rect(topLeadingRadius: 28, topTrailingRadius: 28))
            .offset(y: -26)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            locationManager.requestAuthorization()
            locationManager.startUpdating()
            viewModel.startRainMonitoring()
        }
        .onDisappear {
            locationManager.stopUpdating()
            viewModel.stopRainMonitoring()
        }
        .onReceive(locationManager.$latestLocation.compactMap { $0 }) { location in
            viewModel.record(location: location)
        }
    }

    private var recordingPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            Text(viewModel.trackingState == .paused ? "일시정지" : "기록 중")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(AppTheme.background.opacity(0.72), in: Capsule())
    }

    private var distanceHero: some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(AppFormatters.distanceKm(viewModel.ride.distanceMeters))
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.55)
                Text("km")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textTertiary)
            }

            Text("총 거리")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var currentSpeedKmh: Double {
        viewModel.points.last?.speedMps.map { max(0, $0 * 3.6) } ?? 0
    }
}
