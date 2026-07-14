import FirebaseFirestore
import Foundation

@MainActor
final class CommentRepository: ObservableObject {
    @Published var comments: [Comment] = []

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func listen(spaceId: String, taskId: String) {
        listener?.remove()
        listener = db.collection("spaces").document(spaceId).collection("tasks").document(taskId).collection("comments")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.comments = snapshot?.documents.compactMap { try? $0.data(as: Comment.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }

    @discardableResult
    func addComment(spaceId: String, taskId: String, authorUid: String, text: String) async throws -> String {
        let now = Date()
        let taskRef = db.collection("spaces").document(spaceId).collection("tasks").document(taskId)

        let commentRef = taskRef.collection("comments").document()
        let comment = Comment(authorUid: authorUid, text: text, createdAt: now)
        try commentRef.setData(from: comment)

        try await taskRef.updateData(["updatedAt": now])

        let event = TaskEvent(type: .commented, byUid: authorUid, oldValue: nil, newValue: text, reason: nil, createdAt: now)
        let eventRef = taskRef.collection("events").document()
        try eventRef.setData(from: event)

        return commentRef.documentID
    }
}
