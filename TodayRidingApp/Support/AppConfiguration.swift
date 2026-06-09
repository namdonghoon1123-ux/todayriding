import Foundation
import TodayRidingCore

/// Info.plist 사용자 정의 키 읽기. (Build Settings에 주입)
///
/// 값이 비어 있거나 `$(...)` 미치환 상태면 nil 을 돌려 Mock/로컬 동작으로 폴백한다.
enum AppConfiguration {
    static func string(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else {
            return nil
        }

        return trimmed
    }

    /// 날씨/미세먼지 API 기본 좌표(서울시청). 실기기 GPS 연동 전까지 사용한다.
    static let defaultCoordinate = GeoPoint(latitude: 37.5666, longitude: 126.9784)

    /// Supabase URL + anon key 둘 다 채워져 있을 때만 SupabaseConfiguration 반환.
    static var supabaseConfiguration: SupabaseConfiguration? {
        guard let urlString = string(for: "TODAYRIDING_SUPABASE_URL"),
              let url = URL(string: urlString),
              let anonKey = string(for: "TODAYRIDING_SUPABASE_ANON_KEY") else {
            return nil
        }
        return SupabaseConfiguration(projectURL: url, anonKey: anonKey)
    }
}
