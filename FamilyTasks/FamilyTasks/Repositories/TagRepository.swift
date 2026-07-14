import FirebaseFirestore
import Foundation

@MainActor
final class TagRepository: ObservableObject {
    @Published var tags: [Tag] = []

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func listen(spaceId: String) {
        listener?.remove()
        listener = db.collection("spaces").document(spaceId).collection("tags")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.tags = snapshot?.documents.compactMap { try? $0.data(as: Tag.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }

    func createTag(spaceId: String, name: String, color: String, createdBy: String) async throws {
        let tagRef = db.collection("spaces").document(spaceId).collection("tags").document()
        let tag = Tag(name: name, color: color, createdBy: createdBy, createdAt: Date())
        try tagRef.setData(from: tag)
    }

    func updateTag(spaceId: String, tagId: String, name: String, color: String) async throws {
        try await db.collection("spaces").document(spaceId).collection("tags").document(tagId)
            .updateData(["name": name, "color": color])
    }

    func deleteTag(spaceId: String, tagId: String) async throws {
        try await db.collection("spaces").document(spaceId).collection("tags").document(tagId).delete()
    }
}
