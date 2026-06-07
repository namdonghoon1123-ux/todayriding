import Foundation
import TodayRidingCore

final class ManualClock: @unchecked Sendable {
    var now: Date

    init(now: Date) {
        self.now = now
    }
}

func assert(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fatalError(message)
    }
}

func validateDistanceCalculator() {
    let singlePoint = GeoPoint(latitude: 37.5445, longitude: 127.0557)
    assert(DistanceCalculator.totalDistanceMeters([singlePoint]) == 0, "Single point distance should be zero")

    let points = [
        GeoPoint(latitude: 37.5445, longitude: 127.0557),
        GeoPoint(latitude: 37.5450, longitude: 127.0560),
        GeoPoint(latitude: 37.5455, longitude: 127.0563)
    ]
    let distance = DistanceCalculator.totalDistanceMeters(points)
    assert(distance > 100, "Distance should be greater than 100m")
    assert(distance < 140, "Distance should be less than 140m")
}

func validateRidingScoreCalculator() {
    let now = Date(timeIntervalSince1970: 1_000)
    let goodWeather = WeatherSnapshot(
        observedAt: now,
        locationName: "서울",
        temperatureCelsius: 22,
        feelsLikeCelsius: 22,
        humidityPercent: 55,
        precipitationProbabilityPercent: 10,
        precipitationType: .none,
        skyCondition: "맑음",
        cloudDescription: "구름 조금",
        windSpeedMps: 2,
        windDirection: "서풍",
        sunsetAt: now.addingTimeInterval(4 * 3_600)
    )
    let goodAir = AirQualitySnapshot(pm10: 20, pm25: 10, stationName: "성수", measuredAt: now)
    let goodRecommendation = RidingScoreCalculator.recommendation(
        weather: goodWeather,
        airQuality: goodAir,
        now: now
    )
    assert(goodRecommendation.score == 100, "Clear weather should score 100")
    assert(goodRecommendation.grade == .excellent, "Clear weather should be excellent")

    let badWeather = WeatherSnapshot(
        observedAt: now,
        locationName: "서울",
        temperatureCelsius: 31,
        feelsLikeCelsius: 33,
        humidityPercent: 82,
        precipitationProbabilityPercent: 70,
        precipitationType: .rain,
        skyCondition: "흐림",
        cloudDescription: "구름 많음",
        windSpeedMps: 8,
        windDirection: "서풍",
        sunsetAt: now.addingTimeInterval(60 * 60)
    )
    let badAir = AirQualitySnapshot(pm10: 80, pm25: 45, stationName: "성수", measuredAt: now)
    let badRecommendation = RidingScoreCalculator.recommendation(
        weather: badWeather,
        airQuality: badAir,
        now: now
    )
    assert(badRecommendation.score < 40, "Bad conditions should score below 40")
    assert(badRecommendation.grade == .notRecommended, "Bad conditions should not be recommended")
}

func validateRideTracker() {
    let clock = ManualClock(now: Date(timeIntervalSince1970: 1_000))
    let tracker = RideTracker(clock: { clock.now })
    let ride = tracker.start(weather: nil, airQuality: nil)
    assert(ride.distanceMeters == 0, "New ride should start at zero distance")

    _ = tracker.appendLocation(
        coordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557),
        speedMps: 5,
        horizontalAccuracy: 8
    )

    clock.now = Date(timeIntervalSince1970: 1_060)
    let updatedRide = tracker.appendLocation(
        coordinate: GeoPoint(latitude: 37.5450, longitude: 127.0560),
        speedMps: 6,
        horizontalAccuracy: 8
    )

    assert((updatedRide?.distanceMeters ?? 0) > 50, "Tracker should accumulate distance")
    assert(updatedRide?.durationSeconds == 60, "Tracker should update duration")
    assert(updatedRide?.maxSpeedKmh == 21.6, "Tracker should update max speed")

    clock.now = Date(timeIntervalSince1970: 1_120)
    let finished = tracker.finish()
    assert(finished?.syncStatus == .pending, "Finished ride should be pending sync")
    assert(finished?.endedAt != nil, "Finished ride should have endedAt")
}

func validateFileRideStore() async throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("todayriding-validation-\(UUID().uuidString)", isDirectory: true)
    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    let store = FileRideStore(directoryURL: directory)
    let ride = Ride(
        startedAt: Date(timeIntervalSince1970: 2_000),
        distanceMeters: 1234,
        syncStatus: .pending
    )
    let point = RidePoint(
        rideID: ride.id,
        recordedAt: ride.startedAt,
        coordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557),
        sequence: 0
    )

    try await store.saveRide(ride)
    try await store.appendPoint(point)

    let pendingRides = try await store.loadPendingRides()
    let allRides = try await store.loadRides()
    let loadedPoints = try await store.loadPoints(for: ride.id)

    assert(allRides.map(\.id).contains(ride.id), "FileRideStore should load all rides")
    assert(pendingRides.map(\.id).contains(ride.id), "FileRideStore should load pending rides")
    assert(loadedPoints == [point], "FileRideStore should persist ride points")
}

validateDistanceCalculator()
validateRidingScoreCalculator()
validateRideTracker()
try await validateFileRideStore()

print("TodayRidingValidation passed")
