import FirebaseFirestore
import Foundation

enum SpaceServiceError: LocalizedError {
    case inviteCodeNotFound
    case alreadyPaired

    var errorDescription: String? {
        switch self {
        case .inviteCodeNotFound:
            return "Код приглашения не найден. Проверьте правильность ввода."
        case .alreadyPaired:
            return "К этому пространству уже присоединился второй участник."
        }
    }
}

@MainActor
final class SpaceService: ObservableObject {
    private let db = Firestore.firestore()

    func createSpace(ownerUid: String) async throws -> String {
        let inviteCode = Self.generateInviteCode()
        let spaceRef = db.collection("spaces").document()
        let space = Space(memberUids: [ownerUid], inviteCode: inviteCode, createdAt: Date())
        try spaceRef.setData(from: space)
        try await db.collection("users").document(ownerUid).updateData(["spaceId": spaceRef.documentID])
        return spaceRef.documentID
    }

    func joinSpace(inviteCode: String, uid: String) async throws {
        let snapshot = try await db.collection("spaces")
            .whereField("inviteCode", isEqualTo: inviteCode)
            .limit(to: 1)
            .getDocuments()

        guard let spaceDoc = snapshot.documents.first else {
            throw SpaceServiceError.inviteCodeNotFound
        }

        let memberUids = spaceDoc.data()["memberUids"] as? [String] ?? []
        guard memberUids.count < 2 else {
            throw SpaceServiceError.alreadyPaired
        }

        try await spaceDoc.reference.updateData(["memberUids": FieldValue.arrayUnion([uid])])
        try await db.collection("users").document(uid).updateData(["spaceId": spaceDoc.documentID])
    }

    private static func generateInviteCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}
