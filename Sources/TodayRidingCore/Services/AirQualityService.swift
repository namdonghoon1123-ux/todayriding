import Foundation

public protocol AirQualityService: Sendable {
    func currentAirQuality() async throws -> AirQualitySnapshot
}

public struct AirKoreaService: AirQualityService {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func currentAirQuality() async throws -> AirQualitySnapshot {
        _ = apiKey
        throw RemoteServiceError.notImplemented("AirKoreaService requires nearest station lookup and air-quality endpoint mapping.")
    }
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
