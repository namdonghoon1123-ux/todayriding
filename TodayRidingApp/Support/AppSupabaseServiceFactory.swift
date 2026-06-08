import Foundation
import TodayRidingCore

enum AppSupabaseServiceFactory {
    static func make() -> SupabaseService? {
        guard let urlString = AppConfiguration.string(for: "TODAYRIDING_SUPABASE_URL"),
              let projectURL = URL(string: urlString),
              let anonKey = AppConfiguration.string(for: "TODAYRIDING_SUPABASE_ANON_KEY")
        else {
            return nil
        }

        return HTTPSupabaseService(
            configuration: SupabaseConfiguration(
                projectURL: projectURL,
                anonKey: anonKey
            )
        )
    }
}
