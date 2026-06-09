import Foundation

public protocol PlannedCourseStore: Sendable {
    func load() async throws -> [PlannedCourse]
    func save(_ course: PlannedCourse) async throws
    func delete(_ courseID: UUID) async throws
}

public actor InMemoryPlannedCourseStore: PlannedCourseStore {
    private var courses: [UUID: PlannedCourse] = [:]

    public init(seed: [PlannedCourse] = []) {
        for course in seed { courses[course.id] = course }
    }

    public func load() async throws -> [PlannedCourse] {
        courses.values.sorted { $0.createdAt > $1.createdAt }
    }

    public func save(_ course: PlannedCourse) async throws {
        courses[course.id] = course
    }

    public func delete(_ courseID: UUID) async throws {
        courses.removeValue(forKey: courseID)
    }
}

public actor FilePlannedCourseStore: PlannedCourseStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(directoryURL: URL) {
        self.fileURL = directoryURL.appendingPathComponent("planned-courses.json")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() async throws -> [PlannedCourse] {
        try ensureDirectory()
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        let courses = try decoder.decode([PlannedCourse].self, from: data)
        return courses.sorted { $0.createdAt > $1.createdAt }
    }

    public func save(_ course: PlannedCourse) async throws {
        var existing = (try? await load()) ?? []
        existing.removeAll { $0.id == course.id }
        existing.append(course)
        try ensureDirectory()
        let data = try encoder.encode(existing)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func delete(_ courseID: UUID) async throws {
        let remaining = (try? await load())?.filter { $0.id != courseID } ?? []
        try ensureDirectory()
        let data = try encoder.encode(remaining)
        try data.write(to: fileURL, options: [.atomic])
    }

    private func ensureDirectory() throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }
}
