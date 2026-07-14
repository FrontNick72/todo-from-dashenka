import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if authService.isLoading {
                ProgressView()
            } else if authService.firebaseUser == nil {
                AuthView()
            } else if let spaceId = authService.userProfile?.spaceId {
                SpaceGateView(spaceId: spaceId)
            } else {
                PairingView()
            }
        }
    }
}

#Preview {
    ContentView().environmentObject(AuthService())
}
