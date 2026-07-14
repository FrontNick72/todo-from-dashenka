import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authService: AuthService

    @State private var isSignUp = false
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("ТуДу фром Dashenka")
                .font(.title2.bold())

            if isSignUp {
                TextField("Имя", text: $displayName)
                    .textContentType(.name)
                    .textFieldStyle(.roundedBorder)
            }

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Пароль", text: $password)
                .textContentType(isSignUp ? .newPassword : .password)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button(isSignUp ? "Зарегистрироваться" : "Войти") {
                submit()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || isSubmitting)

            Button(isSignUp ? "У меня уже есть аккаунт" : "Создать аккаунт") {
                isSignUp.toggle()
                errorMessage = nil
            }
            .font(.footnote)
        }
        .padding()
        .disabled(isSubmitting)
    }

    private var isFormValid: Bool {
        guard !email.isEmpty, password.count >= 6 else { return false }
        return isSignUp ? !displayName.isEmpty : true
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password, displayName: displayName)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

#Preview {
    AuthView().environmentObject(AuthService())
}
