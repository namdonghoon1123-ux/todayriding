import CoreLocation
import SwiftUI
import TodayRidingCore

struct RootView: View {
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authController = AuthStateController()
    private let localStore: LocalRideStore
    @State private var trackingViewModel: RideTrackingViewModel?
    @State private var summary: RideSummary?
    @State private var shareSummary: RideSummary?
    @State private var isShowingHistory = false
    @State private var isShowingReport = false
    @State private var isShowingCourses = false

    init() {
        let store = AppLocalRideStoreFactory.make()
        self.localStore = store
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(localStore: store))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                switch authController.state {
                case .checking:
                    ProgressView()
                        .tint(AppTheme.brand)
                case .signedOut where AppSupabaseAuthFactory.isConfigured:
                    AuthView(controller: authController)
                default:
                    mainFlow
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await authController.bootstrap()
            await retryPendingSync()
        }
        .onAppear {
            locationManager.requestOneShotLocation()
            NotificationManager.shared.requestAuthorization()
            NotificationManager.shared.scheduleDailyReminder()
        }
        .onReceive(locationManager.$latestLocation.compactMap { $0 }) { location in
            Task {
                await homeViewModel.updateCoordinate(
                    GeoPoint(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                )
            }
        }
        .onChange(of: authController.state) { _, newState in
            if case .signedIn = newState {
                Task { await retryPendingSync() }
            }
        }
    }

    @ViewBuilder
    private var mainFlow: some View {
        if let shareSummary {
            ShareCardView(summary: shareSummary) {
                self.shareSummary = nil
            }
        } else if isShowingCourses {
            CoursePlannerView(currentUserID: authController.currentUserID) {
                isShowingCourses = false
            }
        } else if isShowingReport {
            ReportView(localStore: localStore) {
                self.isShowingReport = false
            }
        } else if isShowingHistory {
            RideHistoryView(localStore: localStore) { selectedSummary in
                self.summary = selectedSummary
                self.isShowingHistory = false
            } onClose: {
                self.isShowingHistory = false
            }
        } else if let summary {
            RideSummaryView(summary: summary) { updatedSummary in
                self.shareSummary = updatedSummary
            } onDone: {
                self.summary = nil
                self.trackingViewModel = nil
                Task {
                    await homeViewModel.load()
                }
            }
        } else if let trackingViewModel {
            RideTrackingView(viewModel: trackingViewModel) { finishedSummary in
                self.summary = finishedSummary
            }
        } else {
            HomeView(
                viewModel: homeViewModel,
                onStartRide: {
                    trackingViewModel = RideTrackingViewModel(
                        weather: homeViewModel.weather,
                        airQuality: homeViewModel.airQuality,
                        localStore: localStore,
                        supabaseService: makeAuthenticatedSupabaseService()
                    )
                },
                onShowHistory: { isShowingHistory = true },
                onShowReport: { isShowingReport = true },
                onShowCourses: { isShowingCourses = true },
                onSignOut: { Task { await authController.signOut() } }
            )
        }
    }

    /// 앱 실행 시 동기화되지 않은(대기/실패) 라이딩을 Supabase로 재업로드한다.
    /// Supabase 미설정이거나 네트워크 실패 시 데이터는 로컬에 그대로 남는다.
    /// 로그인 상태일 때만 실제로 시도한다.
    private func retryPendingSync() async {
        guard authController.currentSession != nil,
              let supabaseService = makeAuthenticatedSupabaseService() else { return }
        let syncService = RideSyncService(supabaseService: supabaseService)

        let pendingRides = (try? await localStore.loadPendingRides()) ?? []
        for ride in pendingRides where ride.syncStatus == .pending || ride.syncStatus == .failed {
            let points = (try? await localStore.loadPoints(for: ride.id)) ?? []
            let status = await syncService.sync(ride: ride, points: points)

            var updated = ride
            updated.syncStatus = status
            try? await localStore.saveRide(updated)
        }
    }

    private func makeAuthenticatedSupabaseService() -> SupabaseService? {
        AppSupabaseServiceFactory.make(
            accessTokenProvider: { [weak authController] in
                await authController?.freshAccessToken()
            },
            userIDProvider: { [weak authController] in
                await authController?.currentUserID
            }
        )
    }
}
