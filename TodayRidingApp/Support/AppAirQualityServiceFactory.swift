import Foundation
import TodayRidingCore

/// 에어코리아 키가 주입돼 있으면 실제 `AirKoreaService`, 아니면 `MockAirQualityService`.
///
/// `TODAYRIDING_AIRKOREA_STATION`을 지정하면 좌표 기반 측정소 조회를 건너뛴다.
enum AppAirQualityServiceFactory {
    static func make(coordinate: GeoPoint = AppConfiguration.defaultCoordinate) -> AirQualityService {
        guard let apiKey = AppConfiguration.string(for: "TODAYRIDING_AIRKOREA_API_KEY") else {
            return MockAirQualityService()
        }

        return AirKoreaService(
            apiKey: apiKey,
            coordinate: coordinate,
            stationName: AppConfiguration.string(for: "TODAYRIDING_AIRKOREA_STATION")
        )
    }
}
