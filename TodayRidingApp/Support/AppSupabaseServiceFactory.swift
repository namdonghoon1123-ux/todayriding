import Foundation
import TodayRidingCore

enum AppSupabaseServiceFactory {
    /// 토큰/유저 ID provider 없이 만들면 RLS에 막힘. 호출자는 보통
    /// `AuthStateController`에서 토큰을 꺼내 provider로 넘긴다.
    static func make(
        accessTokenProvider: @escaping HTTPSupabaseService.TokenProvider = { nil },
        userIDProvider: @escaping HTTPSupabaseService.UserIDProvider = { nil }
    ) -> SupabaseService? {
        guard let configuration = AppConfiguration.supabaseConfiguration else {
            return nil
        }

        return HTTPSupabaseService(
            configuration: configuration,
            accessTokenProvider: accessTokenProvider,
            userIDProvider: userIDProvider
        )
    }
}
