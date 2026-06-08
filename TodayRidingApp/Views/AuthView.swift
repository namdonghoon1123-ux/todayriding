import SwiftUI
import TodayRidingCore

struct AuthView: View {
    enum Mode { case signIn, signUp }

    @ObservedObject var controller: AuthStateController
    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    formCard

                    PrimaryButton(
                        title: mode == .signIn ? "로그인" : "회원가입",
                        icon: mode == .signIn ? "arrow.right.circle.fill" : "person.badge.plus.fill",
                        action: submit
                    )
                    .disabled(!isFormValid || controller.isWorking)
                    .opacity(isFormValid && !controller.isWorking ? 1 : 0.55)

                    toggleRow

                    if controller.isWorking {
                        ProgressView()
                            .tint(AppTheme.brand)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 32)
            }
        }
        .alert(
            "오늘탈까",
            isPresented: Binding(
                get: { controller.errorMessage != nil },
                set: { isPresented in
                    if !isPresented { controller.errorMessage = nil }
                }
            )
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(controller.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("오늘탈까")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.brand)
            Text(mode == .signIn ? "다시 만나서 반가워요" : "두 분의 라이딩을 함께")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text(mode == .signIn
                 ? "이메일과 비밀번호로 로그인하세요."
                 : "이메일과 6자 이상 비밀번호로 가입하세요.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
        }
    }

    private var formCard: some View {
        VStack(spacing: 12) {
            inputRow(label: "이메일", text: $email, isSecure: false, keyboard: .emailAddress)
            inputRow(label: "비밀번호", text: $password, isSecure: true, keyboard: .default)
        }
        .padding(14)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func inputRow(label: String, text: Binding<String>, isSecure: Bool, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.textTertiary)

            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(AppTheme.surface2, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var toggleRow: some View {
        HStack(spacing: 6) {
            Text(mode == .signIn ? "처음이신가요?" : "이미 계정이 있나요?")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
            Button(action: toggleMode) {
                Text(mode == .signIn ? "회원가입" : "로그인")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.brand)
            }
            Spacer()
        }
    }

    private func toggleMode() {
        mode = (mode == .signIn) ? .signUp : .signIn
        controller.errorMessage = nil
    }

    private func submit() {
        Task {
            if mode == .signIn {
                await controller.signIn(email: email, password: password)
            } else {
                await controller.signUp(email: email, password: password)
            }
        }
    }

    private var isFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.count >= 5 else { return false }
        guard password.count >= 6 else { return false }
        return true
    }
}
