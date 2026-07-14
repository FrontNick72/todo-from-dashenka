import SwiftUI

struct PairingView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var spaceService = SpaceService()

    @State private var joinCode = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Привязка пары")
                .font(.title2.bold())

            Text("Чтобы ставить задачи друг другу, один из вас создаёт общее пространство, а второй вводит код приглашения.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Создать пространство") {
                createSpace()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSubmitting)

            VStack(spacing: 8) {
                Text("или введите код приглашения")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                TextField("Код приглашения", text: $joinCode)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()

                Button("Присоединиться") {
                    joinSpace()
                }
                .disabled(joinCode.isEmpty || isSubmitting)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button("Выйти") {
                try? authService.signOut()
            }
            .font(.footnote)
            .foregroundStyle(.red)
        }
        .padding()
        .disabled(isSubmitting)
    }

    private func createSpace() {
        guard let uid = authService.firebaseUser?.uid else { return }
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                _ = try await spaceService.createSpace(ownerUid: uid)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func joinSpace() {
        guard let uid = authService.firebaseUser?.uid else { return }
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await spaceService.joinSpace(inviteCode: joinCode.uppercased(), uid: uid)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

#Preview {
    PairingView().environmentObject(AuthService())
}
