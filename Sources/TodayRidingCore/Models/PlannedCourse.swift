import Foundation

public struct PlannedCourse: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var userID: UUID?
    public var name: String
    public var notes: String
    public var start: GeoPoint
    public var end: GeoPoint
    public var distanceMeters: Double?
    public var estimatedDurationSeconds: Int?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        userID: UUID? = nil,
        name: String,
        notes: String = "",
        start: GeoPoint,
        end: GeoPoint,
        distanceMeters: Double? = nil,
        estimatedDurationSeconds: Int? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.notes = notes
        self.start = start
        self.end = end
        self.distanceMeters = distanceMeters
        self.estimatedDurationSeconds = estimatedDurationSeconds
        self.createdAt = createdAt
    }
}
