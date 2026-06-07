import Foundation

public protocol AirQualityService: Sendable {
    func currentAirQuality() async throws -> AirQualitySnapshot
}

public struct MockAirQualityService: AirQualityService {
    public init() {}

    public func currentAirQuality() async throws -> AirQualitySnapshot {
        AirQualitySnapshot(
            pm10: 32,
            pm25: 14,
            stationName: "성수동",
            measuredAt: Date()
        )
    }
}

