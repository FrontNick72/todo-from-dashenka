import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Foundation

@MainActor
final class AuthService: ObservableObject {
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var userProfile: UserProfile?
    @Published var isLoading = true

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var profileListener: ListenerRegistration?
    private let db = Firestore.firestore()

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.handleAuthChange(user)
        }
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
        profileListener?.remove()
    }

    private func handleAuthChange(_ user: FirebaseAuth.User?) {
        firebaseUser = user
        profileListener?.remove()
        profileListener = nil

        guard let user else {
            userProfile = nil
            isLoading = false
            return
        }

        profileListener = db.collection("users").document(user.uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.userProfile = try? snapshot?.data(as: UserProfile.self)
                self?.isLoading = false
            }
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let profile = UserProfile(
            displayName: displayName,
            email: email,
            fcmTokens: [],
            spaceId: nil,
            createdAt: Date()
        )
        try db.collection("users").document(result.user.uid).setData(from: profile)
        await saveFcmTokenIfAvailable(uid: result.user.uid)
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await saveFcmTokenIfAvailable(uid: result.user.uid)
    }

    private func saveFcmTokenIfAvailable(uid: String) async {
        guard let token = try? await Messaging.messaging().token() else { return }
        try? await db.collection("users").document(uid).updateData(["fcmTokens": FieldValue.arrayUnion([token])])
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
