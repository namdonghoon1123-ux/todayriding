import Foundation

public protocol UVIndexService: Sendable {
    func currentUVIndex() async throws -> UVIndexSnapshot
}

/// 천체역학 기반 자외선 지수 추정. API 키 없이도 동작.
/// clear-sky 모델: UV = 12.5 × cos(θ_z)^2 × seasonal × 0.95
///   (θ_z = solar zenith angle, seasonal = 1 + 0.04·cos((doy-172)/365·2π))
/// 정확도는 ±2 수준 — 라이딩 가이드 용도에 충분.
public struct EstimatedUVIndexService: UVIndexService {
    private let coordinate: GeoPoint
    private let clock: @Sendable () -> Date

    public init(
        coordinate: GeoPoint,
        clock: @escaping @Sendable () -> Date = Date.init
    ) {
        self.coordinate = coordinate
        self.clock = clock
    }

    public func currentUVIndex() async throws -> UVIndexSnapshot {
        let now = clock()
        let value = Self.estimate(coordinate: coordinate, date: now)
        return UVIndexSnapshot(
            value: value,
            category: UVCategory.category(for: value),
            observedAt: now,
            source: "estimated"
        )
    }

    /// Clear-sky 추정. 외부에서 직접 호출/테스트 가능.
    public static func estimate(coordinate: GeoPoint, date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let year = comps.year ?? 2025
        let month = comps.month ?? 6
        let day = comps.day ?? 21
        let hour = Double(comps.hour ?? 12) + Double(comps.minute ?? 0) / 60.0

        let doy = dayOfYear(year: year, month: month, day: day)
        let declination = 23.45 * sin(degToRad(360.0 * Double(doy - 81) / 365.0))
        let hourAngle = (hour - 12.0) * 15.0  // 정오 = 0, 오후 양수, 오전 음수

        let latRad = degToRad(coordinate.latitude)
        let decRad = degToRad(declination)
        let haRad = degToRad(hourAngle)

        // cos(solar zenith) = sin(lat)·sin(dec) + cos(lat)·cos(dec)·cos(HA)
        let cosZenith = sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(haRad)
        guard cosZenith > 0 else { return 0 }

        // 연중 변동 (여름 +4%, 겨울 -4%)
        let seasonal = 1.0 + 0.04 * cos(degToRad(Double(doy - 172) * 360.0 / 365.0))

        // 최대 UV ≈ 12.5 × cos²(θ_z) × seasonal × 0.95 (구름/대기 감쇠 보정 0.95)
        let raw = 12.5 * cosZenith * cosZenith * seasonal * 0.95
        return max(0, min(15, Int(raw.rounded())))
    }

    private static func degToRad(_ d: Double) -> Double { d * .pi / 180 }

    private static func dayOfYear(year: Int, month: Int, day: Int) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = calendar.date(from: components),
              let ordinality = calendar.ordinality(of: .day, in: .year, for: date) else {
            return 1
        }
        return ordinality
    }
}

public struct FallbackUVIndexService: UVIndexService {
    private let primary: UVIndexService
    private let fallback: UVIndexService

    public init(primary: UVIndexService, fallback: UVIndexService) {
        self.primary = primary
        self.fallback = fallback
    }

    public func currentUVIndex() async throws -> UVIndexSnapshot {
        do {
            return try await primary.currentUVIndex()
        } catch {
            return try await fallback.currentUVIndex()
        }
    }
}
