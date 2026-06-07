import Foundation
import TodayRidingCore

enum AppSupabaseServiceFactory {
    static func make() -> SupabaseService? {
        guard let urlString = configuredString(for: "TODAYRIDING_SUPABASE_URL"),
              let projectURL = URL(string: urlString),
              let anonKey = configuredString(for: "TODAYRIDING_SUPABASE_ANON_KEY")
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

    private static func configuredString(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else {
            return nil
        }

        return trimmed
    }
}

