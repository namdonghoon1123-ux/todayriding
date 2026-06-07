import SwiftUI
import TodayRidingCore

struct RideHistoryView: View {
    @StateObject private var viewModel: RideHistoryViewModel
    let onSelect: (RideSummary) -> Void
    let onClose: () -> Void

    init(
        localStore: LocalRideStore,
        onSelect: @escaping (RideSummary) -> Void,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: RideHistoryViewModel(localStore: localStore))
        self.onSelect = onSelect
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
                } else if viewModel.rides.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.rides) { ride in
                            Button {
                                Task {
                                    if let summary = await viewModel.summary(for: ride) {
                                        onSelect(summary)
                                    }
                                }
                            } label: {
                                RideHistoryRow(ride: ride)
                            }
                            .buttonStyle(.plain)
                        }
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
        .alert(
            "오늘탈까",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        Task {
                            await viewModel.load()
                        }
                    }
                }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("기록")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text("\(viewModel.rides.count)회 라이딩")
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
            Image(systemName: "bicycle")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppTheme.brand)
            Text("아직 저장된 라이딩이 없습니다.")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text("라이딩을 종료하면 이곳에서 다시 확인할 수 있습니다.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(20)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct RideHistoryRow: View {
    let ride: Ride

    var body: some View {
        HStack(spacing: 12) {
            RouteThumbnail()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Text(ride.title ?? "오늘 라이딩")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    SyncStatusPill(status: ride.syncStatus)
                }

                Text(AppFormatters.date(ride.startedAt))
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)

                Text("\(AppFormatters.distanceKm(ride.distanceMeters)) km · \(AppFormatters.duration(ride.durationSeconds)) · \(AppFormatters.speedKmh(ride.averageSpeedKmh)) km/h")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textTertiary)
        }
        .padding(12)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct RouteThumbnail: View {
    var body: some View {
        ZStack {
            AppTheme.surface2
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.brand)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct SyncStatusPill: View {
    let status: RideSyncStatus

    var body: some View {
        Text(label)
            .font(.system(size: 10.5, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.16), in: Capsule())
    }

    private var label: String {
        switch status {
        case .synced:
            return "동기화됨"
        case .failed:
            return "실패"
        case .pending:
            return "대기"
        case .localOnly:
            return "로컬"
        }
    }

    private var color: Color {
        switch status {
        case .synced:
            return AppTheme.good
        case .failed:
            return AppTheme.bad
        case .pending, .localOnly:
            return AppTheme.ok
        }
    }
}

