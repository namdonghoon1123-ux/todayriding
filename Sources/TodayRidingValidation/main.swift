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

func validateRideSyncFallback() async {
    let ride = Ride(startedAt: Date(timeIntervalSince1970: 3_000))
    let syncService = RideSyncService(supabaseService: NoopSupabaseService())
    let status = await syncService.sync(ride: ride, points: [])

    assert(status == .pending, "Unconfigured sync should leave ride pending")
}

func validateKMAGrid() {
    let seoul = KMAGrid.grid(latitude: 37.5665, longitude: 126.9780)
    assert(seoul.nx == 60 && seoul.ny == 127, "Seoul should map to grid (60, 127), got (\(seoul.nx), \(seoul.ny))")

    let busan = KMAGrid.grid(latitude: 35.1796, longitude: 129.0756)
    assert((96...100).contains(busan.nx) && (74...78).contains(busan.ny), "Busan grid out of expected region: (\(busan.nx), \(busan.ny))")
}

func validateSolarCalculator() {
    var kst = Calendar(identifier: .gregorian)
    kst.timeZone = TimeZone(identifier: "Asia/Seoul")!
    func kstMinutes(_ date: Date) -> Int {
        let c = kst.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    let summer = Date(timeIntervalSince1970: 1_718_938_800) // 2024-06-21
    let winter = Date(timeIntervalSince1970: 1_734_750_000) // 2024-12-21

    guard let summerSunset = SolarCalculator.sunset(on: summer, latitude: 37.5665, longitude: 126.9780),
          let winterSunset = SolarCalculator.sunset(on: winter, latitude: 37.5665, longitude: 126.9780)
    else {
        fatalError("Sunset should be computable for Seoul")
    }

    let summerMinutes = kstMinutes(summerSunset)
    let winterMinutes = kstMinutes(winterSunset)
    assert(summerMinutes >= 19 * 60 && summerMinutes <= 20 * 60 + 30, "Seoul summer sunset should be evening, got \(summerMinutes) min")
    assert(winterMinutes >= 16 * 60 + 30 && winterMinutes <= 17 * 60 + 45, "Seoul winter sunset should be ~17h, got \(winterMinutes) min")
    assert(summerMinutes > winterMinutes, "Summer sunset should be later than winter")
}

func validateKoreaTMConverter() {
    let point = KoreaTMConverter.convert(latitude: 37.5666, longitude: 126.9784)
    assert(point.x > 100_000 && point.x < 400_000, "TM x out of bounds: \(point.x)")
    assert(point.y > 100_000 && point.y < 900_000, "TM y out of bounds: \(point.y)")

    let west = KoreaTMConverter.convert(latitude: 37.5, longitude: 126.5)
    let east = KoreaTMConverter.convert(latitude: 37.5, longitude: 127.5)
    assert(east.x > west.x, "Eastward point should have larger TM x")

    let south = KoreaTMConverter.convert(latitude: 35.0, longitude: 127.0)
    let north = KoreaTMConverter.convert(latitude: 38.0, longitude: 127.0)
    assert(north.y > south.y, "Northward point should have larger TM y")
}

func validateGPXExporter() {
    let ride = Ride(
        title: "검증 라이딩 & <tag>",
        startedAt: Date(timeIntervalSince1970: 1_700_000_000),
        distanceMeters: 1234
    )
    let points = [
        RidePoint(
            rideID: ride.id,
            recordedAt: ride.startedAt,
            coordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557),
            altitude: 12,
            speedMps: 5.5,
            sequence: 0
        ),
        RidePoint(
            rideID: ride.id,
            recordedAt: ride.startedAt.addingTimeInterval(60),
            coordinate: GeoPoint(latitude: 37.5450, longitude: 127.0560),
            sequence: 1
        )
    ]

    let gpx = GPXExporter.gpx(for: ride, points: points)
    assert(gpx.hasPrefix("<?xml version=\"1.0\""), "GPX should start with XML declaration")
    assert(gpx.contains("<gpx version=\"1.1\""), "GPX should declare version 1.1")
    let trackPointCount = gpx.components(separatedBy: "<trkpt ").count - 1
    assert(trackPointCount == points.count, "GPX trkpt count should match points, got \(trackPointCount)")
    assert(gpx.contains("lat=\"37.544500\""), "GPX should include formatted latitude")
    assert(gpx.contains("검증 라이딩 &amp; &lt;tag&gt;"), "GPX should escape special characters in title")
    assert((gpx.components(separatedBy: "<ele>").count - 1) == 1, "GPX should include elevation only when present")
}

func validateRainAlertEvaluator() {
    func weather(prob: Int, type: PrecipitationType) -> WeatherSnapshot {
        let now = Date(timeIntervalSince1970: 1_000)
        return WeatherSnapshot(
            observedAt: now,
            locationName: "서울",
            temperatureCelsius: 22,
            feelsLikeCelsius: 22,
            humidityPercent: 55,
            precipitationProbabilityPercent: prob,
            precipitationType: type,
            skyCondition: "흐림",
            cloudDescription: "구름 많음",
            windSpeedMps: 2,
            windDirection: "서풍",
            sunsetAt: now.addingTimeInterval(4 * 3_600)
        )
    }

    assert(RainAlertEvaluator.isRainImminent(weather(prob: 10, type: .rain)), "Rain type should be imminent")
    assert(RainAlertEvaluator.isRainImminent(weather(prob: 60, type: .none)), "60% should be imminent")
    assert(!RainAlertEvaluator.isRainImminent(weather(prob: 59, type: .none)), "59% should not be imminent")

    let safe = weather(prob: 20, type: .none)
    let risky = weather(prob: 80, type: .rain)
    assert(RainAlertEvaluator.shouldWarn(previous: nil, current: risky), "First risky evaluation should warn")
    assert(RainAlertEvaluator.shouldWarn(previous: safe, current: risky), "Safe->risky should warn")
    assert(!RainAlertEvaluator.shouldWarn(previous: risky, current: risky), "Risky->risky should not warn")
    assert(!RainAlertEvaluator.shouldWarn(previous: risky, current: safe), "Risky->safe should not warn")
}

func validateRideStatistics() {
    var utc = Calendar(identifier: .gregorian)
    utc.timeZone = TimeZone(identifier: "UTC")!
    func day(_ year: Int, _ month: Int, _ d: Int) -> Date {
        utc.date(from: DateComponents(year: year, month: month, day: d, hour: 12))!
    }
    func ride(_ start: Date, distance: Double, duration: Int, maxSpeed: Double, avg: Double) -> Ride {
        Ride(
            startedAt: start,
            endedAt: start.addingTimeInterval(Double(duration)),
            durationSeconds: duration,
            movingSeconds: duration,
            distanceMeters: distance,
            averageSpeedKmh: avg,
            maxSpeedKmh: maxSpeed
        )
    }

    let now = day(2023, 11, 14)
    let rides = [
        ride(day(2023, 11, 14), distance: 10_000, duration: 1_800, maxSpeed: 35, avg: 22),
        ride(day(2023, 11, 13), distance: 20_000, duration: 3_600, maxSpeed: 30, avg: 20),
        ride(day(2022, 5, 5), distance: 42_000, duration: 7_200, maxSpeed: 48, avg: 19)
    ]

    let report = RideStatisticsCalculator.report(for: rides, calendar: utc, now: now)
    assert(report.overall.rideCount == 3, "Overall ride count should be 3")
    assert(report.overall.totalDistanceMeters == 72_000, "Overall distance should be 72000")
    assert(report.years.map(\.year) == [2023, 2022], "Years should be sorted desc")
    assert(report.years.first?.stats.rideCount == 2, "2023 should have 2 rides")
    assert(report.records.longestDistanceMeters == 42_000, "Longest distance should be 42000")
    assert(report.records.topSpeedKmh == 48, "Top speed should be 48")
    assert(report.streak.currentDays == 2, "Current streak should be 2 (14th, 13th)")
    assert(report.streak.longestDays == 2, "Longest streak should be 2")

    let empty = RideStatisticsCalculator.report(for: [], calendar: utc, now: now)
    assert(empty == .empty, "Empty rides should produce empty report")
}

func validateRidingCoach() {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current

    // Empty history -> encouraging
    let firstAdvice = RidingCoach.advice(rides: [], recommendation: nil, now: now, calendar: calendar)
    assert(firstAdvice.tone == .encouraging, "Empty rides should give encouraging tone, got \(firstAdvice.tone)")

    // 45-day absence -> reassuring
    let longAgo = Ride(startedAt: now.addingTimeInterval(-60 * 60 * 24 * 45), distanceMeters: 10_000)
    let longAdvice = RidingCoach.advice(rides: [longAgo], recommendation: nil, now: now, calendar: calendar)
    assert(longAdvice.tone == .reassuring, "Long absence should give reassuring tone, got \(longAdvice.tone)")

    // 4+ rides this week -> recoveryReminder
    let week = (0..<4).map { offset in
        Ride(startedAt: now.addingTimeInterval(-Double(offset) * 60 * 60 * 24), distanceMeters: 8_000)
    }
    let recoveryAdvice = RidingCoach.advice(rides: week, recommendation: nil, now: now, calendar: calendar)
    assert(recoveryAdvice.tone == .recoveryReminder, "Overtraining should give recoveryReminder tone, got \(recoveryAdvice.tone)")
}

func validateCourseSuggester() {
    let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
    let shortRide = Ride(
        startedAt: baseDate,
        durationSeconds: 600,
        distanceMeters: 5_000,
        averageSpeedKmh: 12,
        startCoordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557)
    )
    let longRide = Ride(
        startedAt: baseDate.addingTimeInterval(60 * 60 * 24),
        durationSeconds: 3_600,
        distanceMeters: 30_000,
        averageSpeedKmh: 20,
        startCoordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557)
    )
    let fastRide = Ride(
        startedAt: baseDate.addingTimeInterval(60 * 60 * 24 * 2),
        durationSeconds: 1_800,
        distanceMeters: 12_000,
        averageSpeedKmh: 28,
        startCoordinate: GeoPoint(latitude: 37.5445, longitude: 127.0557)
    )

    let suggestions = CourseSuggester.suggest(from: [shortRide, longRide, fastRide])
    assert(suggestions.contains(where: { $0.reason == .longest && $0.ride.id == longRide.id }), "Longest should pick longRide")
    assert(suggestions.contains(where: { $0.reason == .mostRecent && $0.ride.id == fastRide.id }), "Most recent (after longest is taken) should pick fastRide")
    assert(suggestions.contains(where: { $0.reason == .fastest }), "Fastest reason should appear")

    assert(CourseSuggester.suggest(from: []).isEmpty, "Empty input should yield no suggestions")
}

func validateWeatherMath() {
    assert(WeatherMath.windDirection(degrees: 0) == "북풍", "0deg should be 북풍")
    assert(WeatherMath.windDirection(degrees: 90) == "동풍", "90deg should be 동풍")
    assert(WeatherMath.windDirection(degrees: 180) == "남풍", "180deg should be 남풍")
    assert(WeatherMath.windDirection(degrees: 270) == "서풍", "270deg should be 서풍")

    assert(WeatherMath.precipitationType(ptyCode: 0) == .none, "PTY 0 -> none")
    assert(WeatherMath.precipitationType(ptyCode: 1) == .rain, "PTY 1 -> rain")
    assert(WeatherMath.precipitationType(ptyCode: 3) == .snow, "PTY 3 -> snow")

    let hotHumid = WeatherMath.apparentTemperature(temperatureCelsius: 30, humidityPercent: 80, windSpeedMps: 0)
    assert(hotHumid > 30, "Hot humid apparent temp should exceed actual")
    let coldWindy = WeatherMath.apparentTemperature(temperatureCelsius: 5, humidityPercent: 30, windSpeedMps: 10)
    assert(coldWindy < 5, "Cold windy apparent temp should be below actual")
}

validateDistanceCalculator()
validateRidingScoreCalculator()
validateRideTracker()
try await validateFileRideStore()
await validateRideSyncFallback()
validateKMAGrid()
validateSolarCalculator()
validateKoreaTMConverter()
validateWeatherMath()
validateGPXExporter()
validateRideStatistics()
validateRainAlertEvaluator()
validateRidingCoach()
validateCourseSuggester()

print("TodayRidingValidation passed")
