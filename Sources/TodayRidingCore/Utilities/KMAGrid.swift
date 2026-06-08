import Foundation

/// 기상청 단기예보 격자(nx, ny) 변환.
///
/// 기상청 `dfs_xy_conv` Lambert Conformal Conic 투영 공식을 그대로 옮긴 것이다.
/// 기준점은 기상청이 공개한 격자 정의를 따른다.
/// 검증 기준점: 서울(37.5665, 126.9780) -> (nx: 60, ny: 127).
public enum KMAGrid {
    public struct Point: Equatable, Sendable {
        public let nx: Int
        public let ny: Int

        public init(nx: Int, ny: Int) {
            self.nx = nx
            self.ny = ny
        }
    }

    private static let re = 6_371.00877      // 지구 반경(km)
    private static let grid = 5.0            // 격자 간격(km)
    private static let slat1 = 30.0          // 표준 위도 1
    private static let slat2 = 60.0          // 표준 위도 2
    private static let olon = 126.0          // 기준점 경도
    private static let olat = 38.0           // 기준점 위도
    private static let xo = 43.0             // 기준점 X 격자
    private static let yo = 136.0            // 기준점 Y 격자

    public static func grid(latitude: Double, longitude: Double) -> Point {
        let degrad = Double.pi / 180.0
        let reGrid = re / grid
        let slat1r = slat1 * degrad
        let slat2r = slat2 * degrad
        let olonr = olon * degrad
        let olatr = olat * degrad

        var sn = tan(.pi * 0.25 + slat2r * 0.5) / tan(.pi * 0.25 + slat1r * 0.5)
        sn = log(cos(slat1r) / cos(slat2r)) / log(sn)

        var sf = tan(.pi * 0.25 + slat1r * 0.5)
        sf = pow(sf, sn) * cos(slat1r) / sn

        var ro = tan(.pi * 0.25 + olatr * 0.5)
        ro = reGrid * sf / pow(ro, sn)

        var ra = tan(.pi * 0.25 + latitude * degrad * 0.5)
        ra = reGrid * sf / pow(ra, sn)

        var theta = longitude * degrad - olonr
        if theta > .pi { theta -= 2.0 * .pi }
        if theta < -.pi { theta += 2.0 * .pi }
        theta *= sn

        let nx = Int(floor(ra * sin(theta) + xo + 0.5))
        let ny = Int(floor(ro - ra * cos(theta) + yo + 0.5))

        return Point(nx: nx, ny: ny)
    }
}
