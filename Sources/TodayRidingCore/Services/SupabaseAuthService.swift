import Foundation

public struct AuthSession: Codable, Equatable, Sendable {
    public let userID: UUID
    public let accessToken: String
    public let refreshToken: String
    public let expiresAt: Date

    public init(userID: UUID, accessToken: String, refreshToken: String, expiresAt: Date) {
        self.userID = userID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    /// 토큰이 60초 안에 만료될 예정이면 만료된 것으로 본다(미리 갱신하기 위함).
    public func isExpired(now: Date = Date()) -> Bool {
        return now >= expiresAt.addingTimeInterval(-60)
    }
}

public enum SupabaseAuthError: Error, Equatable, Sendable {
    case notConfigured
    case invalidCredentials
    case alreadyRegistered
    case weakPassword
    case rateLimited
    case network
    case decoding
    case unknown(String)
}

public protocol SupabaseAuthService: Sendable {
    func signUp(email: String, password: String) async throws -> AuthSession
    func signIn(email: String, password: String) async throws -> AuthSession
    func refresh(refreshToken: String) async throws -> AuthSession
    func signOut(accessToken: String) async throws
}

public protocol AuthSessionStore: Sendable {
    func load() async -> AuthSession?
    func save(_ session: AuthSession) async throws
    func clear() async
}

/// 메모리 only 세션 저장소. 테스트와 검증, 그리고 Keychain 미지원 환경(Linux CI)을 위한 기본 구현.
public actor InMemoryAuthSessionStore: AuthSessionStore {
    private var session: AuthSession?

    public init(initial: AuthSession? = nil) {
        self.session = initial
    }

    public func load() async -> AuthSession? { session }
    public func save(_ session: AuthSession) async throws { self.session = session }
    public func clear() async { self.session = nil }
}

public struct NoopSupabaseAuthService: SupabaseAuthService {
    public init() {}

    public func signUp(email: String, password: String) async throws -> AuthSession {
        _ = (email, password)
        throw SupabaseAuthError.notConfigured
    }

    public func signIn(email: String, password: String) async throws -> AuthSession {
        _ = (email, password)
        throw SupabaseAuthError.notConfigured
    }

    public func refresh(refreshToken: String) async throws -> AuthSession {
        _ = refreshToken
        throw SupabaseAuthError.notConfigured
    }

    public func signOut(accessToken: String) async throws {
        _ = accessToken
        throw SupabaseAuthError.notConfigured
    }
}

public struct HTTPSupabaseAuthService: SupabaseAuthService {
    private let configuration: SupabaseConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let clock: @Sendable () -> Date

    public init(
        configuration: SupabaseConfiguration,
        session: URLSession = .shared,
        clock: @escaping @Sendable () -> Date = Date.init
    ) {
        self.configuration = configuration
        self.session = session
        self.clock = clock

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    public func signUp(email: String, password: String) async throws -> AuthSession {
        try await postCredentials(path: "signup", queryItems: nil, email: email, password: password)
    }

    public func signIn(email: String, password: String) async throws -> AuthSession {
        try await postCredentials(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            email: email,
            password: password
        )
    }

    public func refresh(refreshToken: String) async throws -> AuthSession {
        let payload = RefreshPayload(refresh_token: refreshToken)
        let response: TokenResponse = try await post(
            path: "token",
            queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")],
            body: payload,
            accessToken: nil
        )
        return try makeSession(from: response)
    }

    public func signOut(accessToken: String) async throws {
        struct Empty: Encodable {}
        let _: EmptyDecodable = try await post(
            path: "logout",
            queryItems: nil,
            body: Empty(),
            accessToken: accessToken
        )
    }

    // MARK: - Private

    private func postCredentials(
        path: String,
        queryItems: [URLQueryItem]?,
        email: String,
        password: String
    ) async throws -> AuthSession {
        let payload = CredentialsPayload(email: email, password: password)
        let response: TokenResponse = try await post(
            path: path,
            queryItems: queryItems,
            body: payload,
            accessToken: nil
        )
        return try makeSession(from: response)
    }

    private func post<Body: Encodable, Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem]?,
        body: Body,
        accessToken: String?
    ) async throws -> Response {
        var components = URLComponents()
        components.scheme = configuration.projectURL.scheme
        components.host = configuration.projectURL.host
        components.port = configuration.projectURL.port
        components.path = "/auth/v1/\(path)"
        components.queryItems = queryItems

        guard let url = components.url else {
            throw SupabaseAuthError.unknown("Invalid auth URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.anonKey, forHTTPHeaderField: "apikey")
        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try encoder.encode(body)

        let (data, httpResponse): (Data, URLResponse)
        do {
            (data, httpResponse) = try await session.data(for: request)
        } catch {
            throw SupabaseAuthError.network
        }

        guard let http = httpResponse as? HTTPURLResponse else {
            throw SupabaseAuthError.unknown("Non-HTTP response")
        }

        if !(200..<300).contains(http.statusCode) {
            throw mapErrorStatus(http.statusCode, data: data)
        }

        if Response.self == EmptyDecodable.self {
            return EmptyDecodable() as! Response
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw SupabaseAuthError.decoding
        }
    }

    private func makeSession(from response: TokenResponse) throws -> AuthSession {
        guard let userID = response.user.id.flatMap(UUID.init(uuidString:)) else {
            throw SupabaseAuthError.decoding
        }
        let expiresAt: Date
        if let absolute = response.expires_at {
            expiresAt = Date(timeIntervalSince1970: TimeInterval(absolute))
        } else if let lifetime = response.expires_in {
            expiresAt = clock().addingTimeInterval(TimeInterval(lifetime))
        } else {
            expiresAt = clock().addingTimeInterval(3600)
        }
        return AuthSession(
            userID: userID,
            accessToken: response.access_token,
            refreshToken: response.refresh_token,
            expiresAt: expiresAt
        )
    }

    private func mapErrorStatus(_ status: Int, data: Data) -> SupabaseAuthError {
        let message = (try? JSONDecoder().decode(ErrorPayload.self, from: data))?.msg
            ?? (try? JSONDecoder().decode(ErrorPayload.self, from: data))?.error_description
            ?? ""

        switch status {
        case 400:
            if message.lowercased().contains("password") {
                return .weakPassword
            }
            return .invalidCredentials
        case 401, 403:
            return .invalidCredentials
        case 422:
            return .alreadyRegistered
        case 429:
            return .rateLimited
        default:
            return .unknown("HTTP \(status) \(message)")
        }
    }
}

// MARK: - Wire payloads

private struct CredentialsPayload: Encodable {
    let email: String
    let password: String
}

private struct RefreshPayload: Encodable {
    let refresh_token: String
}

private struct TokenResponse: Decodable {
    let access_token: String
    let refresh_token: String
    let token_type: String?
    let expires_in: Int?
    let expires_at: Int?
    let user: UserPayload

    struct UserPayload: Decodable {
        let id: String?
        let email: String?
    }
}

private struct ErrorPayload: Decodable {
    let error: String?
    let error_description: String?
    let msg: String?
    let message: String?
}

private struct EmptyDecodable: Decodable {}
