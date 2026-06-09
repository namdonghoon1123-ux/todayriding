import Foundation
import HealthKit
import TodayRidingCore

@MainActor
enum HealthKitWorkoutRecorder {
    static let isEnabledDefaultsKey = "todayriding.health.workoutSaveEnabled"
    private static let store = HKHealthStore()

    static var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: isEnabledDefaultsKey)
    }

    static func enable() async -> Bool {
        guard isAvailable else {
            UserDefaults.standard.set(false, forKey: isEnabledDefaultsKey)
            return false
        }

        var share: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceCycling) {
            share.insert(distance)
        }

        do {
            try await store.requestAuthorization(
                toShare: share,
                read: [HKObjectType.workoutType()]
            )
            UserDefaults.standard.set(true, forKey: isEnabledDefaultsKey)
            return true
        } catch {
            UserDefaults.standard.set(false, forKey: isEnabledDefaultsKey)
            return false
        }
    }

    static func disable() {
        UserDefaults.standard.set(false, forKey: isEnabledDefaultsKey)
    }

    @discardableResult
    static func save(ride: Ride) async -> Bool {
        guard isEnabled, isAvailable else { return false }
        guard let endedAt = ride.endedAt, endedAt > ride.startedAt else { return false }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local()
        )

        do {
            try await builder.beginCollection(at: ride.startedAt)

            if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceCycling),
               ride.distanceMeters > 0 {
                let sample = HKQuantitySample(
                    type: distanceType,
                    quantity: HKQuantity(unit: .meter(), doubleValue: ride.distanceMeters),
                    start: ride.startedAt,
                    end: endedAt
                )
                try await builder.addSamples([sample])
            }

            try await builder.endCollection(at: endedAt)
            _ = try await builder.finishWorkout()
            return true
        } catch {
            return false
        }
    }
}
