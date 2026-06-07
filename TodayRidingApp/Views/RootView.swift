import SwiftUI
import TodayRidingCore

struct RootView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var trackingViewModel: RideTrackingViewModel?
    @State private var summary: RideSummary?
    @State private var shareSummary: RideSummary?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                if let shareSummary {
                    ShareCardView(summary: shareSummary) {
                        self.shareSummary = nil
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
                    HomeView(viewModel: homeViewModel) {
                        trackingViewModel = RideTrackingViewModel(
                            weather: homeViewModel.weather,
                            airQuality: homeViewModel.airQuality
                        )
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

