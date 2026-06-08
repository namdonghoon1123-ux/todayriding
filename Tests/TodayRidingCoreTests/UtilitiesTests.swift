import XCTest
@testable import TodayRidingCore

final class KMAGridTests: XCTestCase {
    func testSeoulReferencePoint() {
        // 기상청 공개 기준점: 서울 -> (60, 127)
        let point = KMAGrid.grid(latitude: 37.5665, longitude: 126.9780)
        XCTAssertEqual(point.nx, 60)
        XCTAssertEqual(point.ny, 127)
    }

    func testBusanIsInExpectedRegion() {
        // 부산 격자(공개 표 기준 약 98, 76 부근)
        let point = KMAGrid.grid(latitude: 35.1796, longitude: 129.0756)
        XCTAssertTrue((96...100).contains(point.nx), "nx=\(point.nx)")
        XCTAssertTrue((74...78).contains(point.ny), "ny=\(point.ny)")
    }
}

final class SolarCalculatorTests: XCTestCase {
    private func kstMinutesOfDay(_ date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    func testSeoulSummerSunsetIsEvening() throws {
        // 2024-06-21 (하지) 정오 KST
        let date = Date(timeIntervalSince1970: 1_718_938_800) // 2024-06-21T03:00:00Z
        let sunset = try XCTUnwrap(SolarCalculator.sunset(on: date, latitude: 37.5665, longitude: 126.9780))
        let minutes = kstMinutesOfDay(sunset)
        // 서울 하지 일몰 ~19:57 KST
        XCTAssertGreaterThanOrEqual(minutes, 19 * 60)
        XCTAssertLessThanOrEqual(minutes, 20 * 60 + 30)
    }

    func testSeoulWinterSunsetIsEarlierThanSummer() throws {
        let summerDate = Date(timeIntervalSince1970: 1_718_938_800) // 2024-06-21
        let winterDate = Date(timeIntervalSince1970: 1_734_750_000) // 2024-12-21T03:00:00Z

        let summerSunset = try XCTUnwrap(SolarCalculator.sunset(on: summerDate, latitude: 37.5665, longitude: 126.9780))
        let winterSunset = try XCTUnwrap(SolarCalculator.sunset(on: winterDate, latitude: 37.5665, longitude: 126.9780))

        let winterMinutes = kstMinutesOfDay(winterSunset)
        // 서울 동지 일몰 ~17:17 KST
        XCTAssertGreaterThanOrEqual(winterMinutes, 16 * 60 + 30)
        XCTAssertLessThanOrEqual(winterMinutes, 17 * 60 + 45)

        XCTAssertGreaterThan(kstMinutesOfDay(summerSunset), winterMinutes)
    }
}

final class KoreaTMConverterTests: XCTestCase {
    func testWithinKoreaBounds() {
        let point = KoreaTMConverter.convert(latitude: 37.5666, longitude: 126.9784)
        XCTAssertGreaterThan(point.x, 100_000)
        XCTAssertLessThan(point.x, 400_000)
        XCTAssertGreaterThan(point.y, 100_000)
        XCTAssertLessThan(point.y, 900_000)
    }

    func testEastwardIncreasesX() {
        let west = KoreaTMConverter.convert(latitude: 37.5, longitude: 126.5)
        let east = KoreaTMConverter.convert(latitude: 37.5, longitude: 127.5)
        XCTAssertGreaterThan(east.x, west.x)
    }

    func testNorthwardIncreasesY() {
        let south = KoreaTMConverter.convert(latitude: 35.0, longitude: 127.0)
        let north = KoreaTMConverter.convert(latitude: 38.0, longitude: 127.0)
        XCTAssertGreaterThan(north.y, south.y)
    }
}

final class WeatherMathTests: XCTestCase {
    func testWindDirectionCardinalPoints() {
        XCTAssertEqual(WeatherMath.windDirection(degrees: 0), "북풍")
        XCTAssertEqual(WeatherMath.windDirection(degrees: 90), "동풍")
        XCTAssertEqual(WeatherMath.windDirection(degrees: 180), "남풍")
        XCTAssertEqual(WeatherMath.windDirection(degrees: 270), "서풍")
        XCTAssertEqual(WeatherMath.windDirection(degrees: 360), "북풍")
    }

    func testPrecipitationTypeMapping() {
        XCTAssertEqual(WeatherMath.precipitationType(ptyCode: 0), .none)
        XCTAssertEqual(WeatherMath.precipitationType(ptyCode: 1), .rain)
        XCTAssertEqual(WeatherMath.precipitationType(ptyCode: 2), .rainAndSnow)
        XCTAssertEqual(WeatherMath.precipitationType(ptyCode: 3), .snow)
        XCTAssertEqual(WeatherMath.precipitationType(ptyCode: 4), .shower)
        XCTAssertEqual(WeatherMath.precipitationType(ptyCode: 5), .rain)
    }

    func testApparentTemperatureHotHumidFeelsHotter() {
        let apparent = WeatherMath.apparentTemperature(
            temperatureCelsius: 30,
            humidityPercent: 80,
            windSpeedMps: 0
        )
        XCTAssertGreaterThan(apparent, 30)
    }

    func testApparentTemperatureColdWindyFeelsColder() {
        let apparent = WeatherMath.apparentTemperature(
            temperatureCelsius: 5,
            humidityPercent: 30,
            windSpeedMps: 10
        )
        XCTAssertLessThan(apparent, 5)
    }
}
