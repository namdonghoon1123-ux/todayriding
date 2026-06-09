import Foundation
import TodayRidingCore

/// 자외선지수 서비스 팩토리. 기본은 천체역학 추정(외부 API 키 불필요).
/// 향후 KMA 생활기상지수(`getUVIdxV4`) 직결 시 여기서 분기.
enum AppUVIndexServiceFactory {
    static func make(coordinate: GeoPoint) -> UVIndexService {
        EstimatedUVIndexService(coordinate: coordinate)
    }
}
