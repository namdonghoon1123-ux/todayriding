import Foundation
import TodayRidingCore

enum AppPlannedCourseStoreFactory {
    static func make() -> PlannedCourseStore {
        guard let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return InMemoryPlannedCourseStore()
        }

        return FilePlannedCourseStore(
            directoryURL: applicationSupportURL
                .appendingPathComponent("TodayRiding", isDirectory: true)
                .appendingPathComponent("Courses", isDirectory: true)
        )
    }
}
