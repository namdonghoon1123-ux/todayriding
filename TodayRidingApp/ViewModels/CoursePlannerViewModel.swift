import Combine
import CoreLocation
import Foundation
import MapKit
import TodayRidingCore

@MainActor
final class CoursePlannerViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var searchResults: [MKMapItem] = []
    @Published var origin: CLLocationCoordinate2D?
    @Published var destination: CLLocationCoordinate2D?
    @Published private(set) var routePolyline: MKPolyline?
    @Published private(set) var routeDistanceMeters: Double?
    @Published private(set) var routeDurationSeconds: TimeInterval?
    @Published private(set) var savedCourses: [PlannedCourse] = []
    @Published private(set) var weatherPreview: [UUID: WeatherSnapshot] = [:]
    @Published private(set) var airPreview: [UUID: AirQualitySnapshot] = [:]
    @Published var errorMessage: String?
    @Published var isWorking = false

    private let courseStore: PlannedCourseStore
    private let userIDProvider: () -> UUID?

    init(
        courseStore: PlannedCourseStore = AppPlannedCourseStoreFactory.make(),
        userIDProvider: @escaping () -> UUID? = { nil }
    ) {
        self.courseStore = courseStore
        self.userIDProvider = userIDProvider
    }

    func loadSavedCourses() async {
        do {
            let courses = try await courseStore.load()
            savedCourses = courses
            await refreshPreviews(for: courses)
        } catch {
            errorMessage = "저장된 코스를 불러오지 못했습니다."
        }
    }

    func search() async {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let center = origin {
            request.region = MKCoordinateRegion(
                center: center,
                latitudinalMeters: 20_000,
                longitudinalMeters: 20_000
            )
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            searchResults = response.mapItems
        } catch {
            searchResults = []
        }
    }

    func selectDestination(_ item: MKMapItem) {
        destination = item.placemark.coordinate
        searchText = item.name ?? item.placemark.title ?? ""
        searchResults = []
        Task { await calculateRoute() }
    }

    func setOrigin(_ coordinate: CLLocationCoordinate2D) {
        origin = coordinate
        Task { await calculateRoute() }
    }

    func calculateRoute() async {
        guard let origin, let destination else { return }
        isWorking = true
        defer { isWorking = false }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        // MapKit은 자전거 라우팅을 직접 제공하지 않으므로 자전거에 가장 가까운 도보 라우팅 사용.
        request.transportType = .walking

        do {
            let response = try await MKDirections(request: request).calculate()
            if let route = response.routes.first {
                routePolyline = route.polyline
                routeDistanceMeters = route.distance
                // 도보 시간 ÷ 3 = 자전거 대략 (~3배 빠름)
                routeDurationSeconds = route.expectedTravelTime / 3.0
            }
        } catch {
            errorMessage = "경로를 계산하지 못했습니다."
        }
    }

    func saveCurrentRoute(name: String) async {
        guard let origin, let destination else {
            errorMessage = "출발지와 도착지를 모두 지정해주세요."
            return
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmed.isEmpty ? "이름 없는 코스" : trimmed

        let course = PlannedCourse(
            userID: userIDProvider(),
            name: title,
            start: GeoPoint(latitude: origin.latitude, longitude: origin.longitude),
            end: GeoPoint(latitude: destination.latitude, longitude: destination.longitude),
            distanceMeters: routeDistanceMeters,
            estimatedDurationSeconds: routeDurationSeconds.map { Int($0) }
        )

        do {
            try await courseStore.save(course)
            await loadSavedCourses()
        } catch {
            errorMessage = "코스 저장에 실패했습니다."
        }
    }

    func delete(_ course: PlannedCourse) async {
        do {
            try await courseStore.delete(course.id)
            await loadSavedCourses()
        } catch {
            errorMessage = "삭제에 실패했습니다."
        }
    }

    /// 저장된 각 코스의 도착지 좌표로 날씨/미세먼지를 미리 fetch.
    private func refreshPreviews(for courses: [PlannedCourse]) async {
        for course in courses {
            let endPoint = course.end
            let weatherService = AppWeatherServiceFactory.make(coordinate: endPoint)
            let airService = AppAirQualityServiceFactory.make(coordinate: endPoint)
            async let weather = try? await weatherService.currentWeather()
            async let air = try? await airService.currentAirQuality()
            if let w = await weather { weatherPreview[course.id] = w }
            if let a = await air { airPreview[course.id] = a }
        }
    }
}
