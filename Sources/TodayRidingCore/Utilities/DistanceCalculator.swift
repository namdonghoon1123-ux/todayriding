import Foundation

public enum DistanceCalculator {
    private static let earthRadiusMeters = 6_371_000.0

    public static func totalDistanceMeters(_ coordinates: [GeoPoint]) -> Double {
        guard coordinates.count > 1 else { return 0 }

        return zip(coordinates, coordinates.dropFirst())
            .map(distanceMeters)
            .reduce(0, +)
    }

    public static func distanceMeters(from: GeoPoint, to: GeoPoint) -> Double {
        let fromLatitude = degreesToRadians(from.latitude)
        let toLatitude = degreesToRadians(to.latitude)
        let latitudeDelta = degreesToRadians(to.latitude - from.latitude)
        let longitudeDelta = degreesToRadians(to.longitude - from.longitude)

        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(fromLatitude) * cos(toLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadiusMeters * c
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}

