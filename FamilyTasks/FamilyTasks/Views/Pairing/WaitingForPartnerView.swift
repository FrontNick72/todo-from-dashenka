import SwiftUI

struct WaitingForPartnerView: View {
    let inviteCode: String
    @EnvironmentObject var authService: AuthService

    var body: some View {
        VStack(spacing: 20) {
            Text("Ждём вторую половину")
                .font(.title2.bold())

            Text("Передайте партнёру этот код на экране «Привязка пары»:")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text(inviteCode)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            ShareLink(item: inviteCode) {
                Label("Поделиться кодом", systemImage: "square.and.arrow.up")
            }

            Button("Выйти") {
                try? authService.signOut()
            }
            .font(.footnote)
            .foregroundStyle(.red)
        }
        .padding()
    }
}

#Preview {
    WaitingForPartnerView(inviteCode: "AB12CD").environmentObject(AuthService())
}
