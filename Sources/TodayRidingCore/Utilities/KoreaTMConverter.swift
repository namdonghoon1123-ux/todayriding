import Foundation

/// WGS84 위경도 -> 한국 TM 좌표(EPSG:5181, Korea 2000 / Central Belt 2010) 변환.
///
/// 에어코리아 측정소정보 `getNearbyMsrstnList`가 요구하는 tmX, tmY(미터)를 만든다.
/// GRS80 타원체, 중부원점(lat0=38°, lon0=127°, k0=1), False Easting 200000, False Northing 600000.
///
/// 주의: 이 투영 정의는 에어코리아가 사용하는 표준값을 가정한 것이다. 실제 API 응답과의
/// 정합성은 실제 키로 검증이 필요하다.(`TODO.md` 참고)
public enum KoreaTMConverter {
    public struct TMPoint: Equatable, Sendable {
        public let x: Double
        public let y: Double

        public init(x: Double, y: Double) {
            self.x = x
            self.y = y
        }
    }

    // GRS80
    private static let a = 6_378_137.0
    private static let f = 1.0 / 298.257222101
    private static let lat0 = 38.0
    private static let lon0 = 127.0
    private static let k0 = 1.0
    private static let falseEasting = 200_000.0
    private static let falseNorthing = 600_000.0

    public static func convert(latitude: Double, longitude: Double) -> TMPoint {
        let degrad = Double.pi / 180.0
        let lat = latitude * degrad
        let lon = longitude * degrad
        let lat0r = lat0 * degrad
        let lon0r = lon0 * degrad

        let b = a * (1 - f)
        let e2 = (a * a - b * b) / (a * a)
        let ep2 = (a * a - b * b) / (b * b)

        let sinLat = sin(lat)
        let cosLat = cos(lat)
        let tanLat = tan(lat)

        let n = a / sqrt(1 - e2 * sinLat * sinLat)
        let t = tanLat * tanLat
        let c = ep2 * cosLat * cosLat
        let aTerm = cosLat * (lon - lon0r)

        let m = meridionalArc(lat: lat, e2: e2)
        let m0 = meridionalArc(lat: lat0r, e2: e2)

        let easting = falseEasting + k0 * n * (
            aTerm
            + (1 - t + c) * pow(aTerm, 3) / 6
            + (5 - 18 * t + t * t + 72 * c - 58 * ep2) * pow(aTerm, 5) / 120
        )

        let northing = falseNorthing + k0 * (
            m - m0 + n * tanLat * (
                aTerm * aTerm / 2
                + (5 - t + 9 * c + 4 * c * c) * pow(aTerm, 4) / 24
                + (61 - 58 * t + t * t + 600 * c - 330 * ep2) * pow(aTerm, 6) / 720
            )
        )

        return TMPoint(x: easting, y: northing)
    }

    private static func meridionalArc(lat: Double, e2: Double) -> Double {
        let e4 = e2 * e2
        let e6 = e4 * e2
        return a * (
            (1 - e2 / 4 - 3 * e4 / 64 - 5 * e6 / 256) * lat
            - (3 * e2 / 8 + 3 * e4 / 32 + 45 * e6 / 1024) * sin(2 * lat)
            + (15 * e4 / 256 + 45 * e6 / 1024) * sin(4 * lat)
            - (35 * e6 / 3072) * sin(6 * lat)
        )
    }
}
