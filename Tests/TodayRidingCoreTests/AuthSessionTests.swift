import XCTest
@testable import TodayRidingCore

final class AuthSessionTests: XCTestCase {
    func testFreshSessionIsNotExpired() {
        let session = AuthSession(
            userID: UUID(),
            accessToken: "atk",
            refreshToken: "rtk",
            expiresAt: Date().addingTimeInterval(3_600)
        )
        XCTAssertFalse(session.isExpired())
    }

    func testSessionWithinSixtySecondsOfExpiryCountsAsExpired() {
        let now = Date()
        let session = AuthSession(
            userID: UUID(),
            accessToken: "atk",
            refreshToken: "rtk",
            expiresAt: now.addingTimeInterval(30) // 60s 안에 만료
        )
        XCTAssertTrue(session.isExpired(now: now))
    }

    func testAlreadyExpiredSessionIsExpired() {
        let session = AuthSession(
            userID: UUID(),
            accessToken: "atk",
            refreshToken: "rtk",
            expiresAt: Date().addingTimeInterval(-10)
        )
        XCTAssertTrue(session.isExpired())
    }

    func testSessionCodableRoundTrip() throws {
        let original = AuthSession(
            userID: UUID(),
            accessToken: "atk-1234",
            refreshToken: "rtk-5678",
            expiresAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(AuthSession.self, from: data)

        XCTAssertEqual(restored, original)
    }
}

final class InMemoryAuthSessionStoreTests: XCTestCase {
    func testSaveAndLoadRoundTrip() async throws {
        let store = InMemoryAuthSessionStore()
        let session = AuthSession(
            userID: UUID(),
            accessToken: "atk",
            refreshToken: "rtk",
            expiresAt: Date().addingTimeInterval(3_600)
        )

        var loaded = await store.load()
        XCTAssertNil(loaded)

        try await store.save(session)
        loaded = await store.load()
        XCTAssertEqual(loaded, session)

        await store.clear()
        loaded = await store.load()
        XCTAssertNil(loaded)
    }
}

final class NoopSupabaseAuthServiceTests: XCTestCase {
    func testEveryMethodThrowsNotConfigured() async {
        let service = NoopSupabaseAuthService()
        await assertThrows(.notConfigured) { try await service.signUp(email: "a@b.c", password: "secret") }
        await assertThrows(.notConfigured) { try await service.signIn(email: "a@b.c", password: "secret") }
        await assertThrows(.notConfigured) { try await service.refresh(refreshToken: "rtk") }
        await assertThrows(.notConfigured) { try await service.signOut(accessToken: "atk") }
    }

    private func assertThrows(_ expected: SupabaseAuthError, _ work: () async throws -> Void) async {
        do {
            try await work()
            XCTFail("Expected \(expected), got success")
        } catch let error as SupabaseAuthError {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Expected SupabaseAuthError.\(expected), got \(error)")
        }
    }
}
