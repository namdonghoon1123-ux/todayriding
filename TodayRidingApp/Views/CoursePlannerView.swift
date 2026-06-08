import MapKit
import SwiftUI
import TodayRidingCore

struct CoursePlannerView: View {
    @StateObject private var viewModel: CoursePlannerViewModel
    @State private var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5666, longitude: 126.9784),
        latitudinalMeters: 6_000,
        longitudinalMeters: 6_000
    ))
    @State private var saveSheetPresented = false
    @State private var newCourseName = ""
    let onClose: () -> Void

    init(courseStore: PlannedCourseStore? = nil, currentUserID: UUID? = nil, onClose: @escaping () -> Void) {
        let store = courseStore ?? AppPlannedCourseStoreFactory.make()
        _viewModel = StateObject(wrappedValue: CoursePlannerViewModel(
            courseStore: store,
            userIDProvider: { currentUserID }
        ))
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 6)

            if !viewModel.searchResults.isEmpty {
                searchResults
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }

            mapArea

            if viewModel.routePolyline != nil {
                routeSummary
            }

            if !viewModel.savedCourses.isEmpty {
                savedCoursesList
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await viewModel.loadSavedCourses()
        }
        .alert(
            "코스",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in
                    if !isPresented { viewModel.errorMessage = nil }
                }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $saveSheetPresented) {
            saveSheet
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("코스 짜기")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                Text("출발지 = 지도 길게 누르기, 도착지 = 검색")
                    .font(.system(size: 12, weight: .semibold))
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textTertiary)
            TextField("도착지 검색 (예: 한강공원)", text: $viewModel.searchText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.search() }
                }
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(viewModel.searchResults.prefix(5), id: \.self) { item in
                Button {
                    viewModel.selectDestination(item)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(AppTheme.brand)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Unknown")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                            if let address = item.placemark.title {
                                Text(address)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
    }

    private var mapArea: some View {
        MapReader { proxy in
            Map(position: $camera) {
                if let origin = viewModel.origin {
                    Annotation("출발", coordinate: origin) {
                        Image(systemName: "figure.outdoor.cycle")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(AppTheme.brand, in: Circle())
                    }
                }
                if let destination = viewModel.destination {
                    Annotation("도착", coordinate: destination) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(AppTheme.good, in: Circle())
                    }
                }
                if let polyline = viewModel.routePolyline {
                    MapPolyline(polyline)
                        .stroke(AppTheme.brand, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .onTapGesture { location in
                if let coord = proxy.convert(location, from: .local) {
                    viewModel.setOrigin(coord)
                }
            }
        }
        .frame(height: 320)
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var routeSummary: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let distance = viewModel.routeDistanceMeters {
                    Text("\(String(format: "%.1f", distance / 1_000)) km")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                if let duration = viewModel.routeDurationSeconds {
                    Text("예상 \(formatDuration(duration))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            Spacer()
            Button {
                newCourseName = ""
                saveSheetPresented = true
            } label: {
                Label("저장", systemImage: "tray.and.arrow.down.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AppTheme.brand, in: Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var savedCoursesList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("저장된 코스")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textTertiary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.savedCourses) { course in
                        savedCourseCard(course)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    private func savedCourseCard(_ course: PlannedCourse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)

            if let distance = course.distanceMeters {
                Text("\(String(format: "%.1f", distance / 1_000)) km")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.brand)
            }

            HStack(spacing: 6) {
                if let weather = viewModel.weatherPreview[course.id] {
                    Label("\(Int(weather.temperatureCelsius))°", systemImage: "thermometer.medium")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(AppTheme.ok)
                }
                if let air = viewModel.airPreview[course.id] {
                    Label("PM\(air.pm25)", systemImage: "aqi.medium")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(AppTheme.good)
                }
            }

            Spacer(minLength: 0)

            HStack {
                Button {
                    viewModel.origin = CLLocationCoordinate2D(
                        latitude: course.start.latitude,
                        longitude: course.start.longitude
                    )
                    viewModel.destination = CLLocationCoordinate2D(
                        latitude: course.end.latitude,
                        longitude: course.end.longitude
                    )
                    Task { await viewModel.calculateRoute() }
                } label: {
                    Text("열기")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundStyle(AppTheme.brand)
                }
                Spacer()
                Button {
                    Task { await viewModel.delete(course) }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
        }
        .padding(12)
        .frame(width: 170, height: 150, alignment: .topLeading)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var saveSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("코스 이름")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textTertiary)
            TextField("예: 한강 → 양수리", text: $newCourseName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(12)
                .background(AppTheme.surface2, in: RoundedRectangle(cornerRadius: 12))

            Button {
                Task {
                    await viewModel.saveCurrentRoute(name: newCourseName)
                    saveSheetPresented = false
                }
            } label: {
                Text("저장")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.brand, in: RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.background.ignoresSafeArea())
        .presentationDetents([.height(220)])
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3_600
        let m = (Int(seconds) % 3_600) / 60
        if h > 0 { return "\(h)시간 \(m)분" }
        return "\(m)분"
    }
}
