import Combine
import Foundation
import TodayRidingCore

@MainActor
final class AuthStateController: ObservableObject {
    enum State: Equatable {
        case checking
        case signedOut
        case signedIn(AuthSession)
    }

    @Published private(set) var state: State = .checking
    @Published var errorMessage: String?
    @Published private(set) var isWorking = false

    private let authService: SupabaseAuthService
    private let sessionStore: AuthSessionStore
    private let isConfigured: Bool

    init(
        authService: SupabaseAuthService = AppSupabaseAuthFactory.make(),
        sessionStore: AuthSessionStore = KeychainAuthSessionStore(),
        isConfigured: Bool = AppSupabaseAuthFactory.isConfigured
    ) {
        self.authService = authService
        self.sessionStore = sessionStore
        self.isConfigured = isConfigured
    }

    var currentSession: AuthSession? {
        if case .signedIn(let session) = state {
            return session
        }
        return nil
    }

    var currentUserID: UUID? {
        currentSession?.userID
    }

    /// Supabase 미설정이면 자동으로 anonymous local 모드.
    /// 설정돼 있으면 Keychain에서 토큰 복원 시도 → 만료면 refresh → 실패면 signedOut.
    func bootstrap() async {
        guard isConfigured else {
            state = .signedOut
            return
        }

        if let restored = await sessionStore.load() {
            if restored.isExpired() {
                do {
                    let refreshed = try await authService.refresh(refreshToken: restored.refreshToken)
                    try await sessionStore.save(refreshed)
                    state = .signedIn(refreshed)
                } catch {
                    await sessionStore.clear()
                    state = .signedOut
                }
            } else {
                state = .signedIn(restored)
            }
        } else {
            state = .signedOut
        }
    }

    func signUp(email: String, password: String) async {
        await run {
            let session = try await self.authService.signUp(email: email, password: password)
            try await self.sessionStore.save(session)
            self.state = .signedIn(session)
        }
    }

    func signIn(email: String, password: String) async {
        await run {
            let session = try await self.authService.signIn(email: email, password: password)
            try await self.sessionStore.save(session)
            self.state = .signedIn(session)
        }
    }

    func signOut() async {
        if let session = currentSession {
            try? await authService.signOut(accessToken: session.accessToken)
        }
        await sessionStore.clear()
        state = .signedOut
    }

    /// 외부에서 토큰이 필요할 때 호출. 만료된 토큰은 자동 갱신, 실패 시 signedOut + nil.
    func freshAccessToken() async -> String? {
        guard case .signedIn(var session) = state else { return nil }

        if session.isExpired() {
            do {
                session = try await authService.refresh(refreshToken: session.refreshToken)
                try await sessionStore.save(session)
                state = .signedIn(session)
            } catch {
                await sessionStore.clear()
                state = .signedOut
                return nil
            }
        }
        return session.accessToken
    }

    private func run(_ work: @escaping () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do {
            try await work()
        } catch let error as SupabaseAuthError {
            errorMessage = message(for: error)
        } catch {
            errorMessage = "예기치 못한 오류가 발생했습니다."
        }
    }

    private func message(for error: SupabaseAuthError) -> String {
        switch error {
        case .notConfigured:
            return "Supabase 설정이 비어 있습니다. Build Settings 키를 확인해주세요."
        case .invalidCredentials:
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .alreadyRegistered:
            return "이미 가입된 이메일입니다. 로그인을 시도해주세요."
        case .weakPassword:
            return "비밀번호는 6자 이상이어야 합니다."
        case .rateLimited:
            return "요청이 잦습니다. 잠시 후 다시 시도해주세요."
        case .network:
            return "네트워크 연결을 확인해주세요."
        case .decoding:
            return "서버 응답을 해석하지 못했습니다."
        case .unknown(let detail):
            return "오류: \(detail)"
        }
    }
}
