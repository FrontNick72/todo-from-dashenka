import SwiftUI
import FirebaseFirestore

@MainActor
final class SpaceViewModel: ObservableObject {
    @Published var space: Space?
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func listen(spaceId: String) {
        listener?.remove()
        listener = db.collection("spaces").document(spaceId)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.space = try? snapshot?.data(as: Space.self)
            }
    }

    deinit {
        listener?.remove()
    }
}

struct SpaceGateView: View {
    let spaceId: String
    @StateObject private var viewModel = SpaceViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        Group {
            if let space = viewModel.space {
                if space.memberUids.count >= 2, let currentUid = authService.firebaseUser?.uid,
                   let partnerUid = space.memberUids.first(where: { $0 != currentUid }) {
                    MainView(spaceId: spaceId, currentUid: currentUid, partnerUid: partnerUid)
                } else {
                    WaitingForPartnerView(inviteCode: space.inviteCode)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear { viewModel.listen(spaceId: spaceId) }
    }
}
