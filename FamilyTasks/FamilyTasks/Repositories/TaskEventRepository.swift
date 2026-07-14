import FirebaseFirestore

@MainActor
final class TaskEventRepository: ObservableObject {
    @Published var events: [TaskEvent] = []

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func listen(spaceId: String, taskId: String) {
        listener?.remove()
        listener = db.collection("spaces").document(spaceId).collection("tasks").document(taskId).collection("events")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.events = snapshot?.documents.compactMap { try? $0.data(as: TaskEvent.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }
}
