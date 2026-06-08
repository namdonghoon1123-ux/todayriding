import XCTest
@testable import TodayRidingCore

final class GPXExporterTests: XCTestCase {
    private func sampleRide(title: String? = "테스트 라이딩") -> (Ride, [RidePoint]) {
        let ride = Ride(
            title: title,
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
        return (ride, points)
    }

    func testProducesValidGPXStructure() {
        let (ride, points) = sampleRide()
        let gpx = GPXExporter.gpx(for: ride, points: points)

        XCTAssertTrue(gpx.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        XCTAssertTrue(gpx.contains("<gpx version=\"1.1\""))
        XCTAssertTrue(gpx.contains("<trk>"))
        XCTAssertTrue(gpx.contains("</gpx>"))
    }

    func testTrackPointCountMatchesPoints() {
        let (ride, points) = sampleRide()
        let gpx = GPXExporter.gpx(for: ride, points: points)

        let count = gpx.components(separatedBy: "<trkpt ").count - 1
        XCTAssertEqual(count, points.count)
    }

    func testIncludesCoordinatesAndOptionalElevation() {
        let (ride, points) = sampleRide()
        let gpx = GPXExporter.gpx(for: ride, points: points)

        XCTAssertTrue(gpx.contains("lat=\"37.544500\""))
        XCTAssertTrue(gpx.contains("lon=\"127.055700\""))
        // 첫 포인트만 고도 보유 -> <ele> 1회
        XCTAssertEqual(gpx.components(separatedBy: "<ele>").count - 1, 1)
    }

    func testEscapesSpecialCharactersInTitle() {
        let (ride, points) = sampleRide(title: "Tom & Jerry <ride>")
        let gpx = GPXExporter.gpx(for: ride, points: points)

        XCTAssertTrue(gpx.contains("Tom &amp; Jerry &lt;ride&gt;"))
        XCTAssertFalse(gpx.contains("Tom & Jerry <ride>"))
    }
}
