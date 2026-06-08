import Foundation
import TodayRidingCore

enum AppSupabaseAuthFactory {
    /// Build Settings 키가 모두 채워져 있을 때만 HTTP 어센서비스를 만든다.
    /// 키가 없으면 NoopSupabaseAuthService로 동작 (signUp/signIn 호출 시 notConfigured 에러).
    static func make() -> SupabaseAuthService {
        guard let config = AppConfiguration.supabaseConfiguration else {
            return NoopSupabaseAuthService()
        }
        return HTTPSupabaseAuthService(configuration: config)
    }

    static var isConfigured: Bool {
        AppConfiguration.supabaseConfiguration != nil
    }
}
