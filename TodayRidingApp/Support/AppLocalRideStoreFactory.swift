import Foundation
import TodayRidingCore

enum AppLocalRideStoreFactory {
    static func make() -> LocalRideStore {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return InMemoryRideStore()
        }

        return FileRideStore(
            directoryURL: applicationSupportURL
                .appendingPathComponent("TodayRiding", isDirectory: true)
                .appendingPathComponent("Rides", isDirectory: true)
        )
    }
}

