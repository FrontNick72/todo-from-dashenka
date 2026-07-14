import FirebaseFirestore
import FirebaseStorage
import Foundation

enum TaskRepositoryError: LocalizedError {
    case reasonRequired

    var errorDescription: String? {
        "Перенос даты требует указания причины."
    }
}

@MainActor
final class TaskRepository: ObservableObject {
    @Published var tasks: [TaskItem] = []

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func listen(spaceId: String) {
        listener?.remove()
        listener = db.collection("spaces").document(spaceId).collection("tasks")
            .order(by: "dueAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.tasks = snapshot?.documents.compactMap { try? $0.data(as: TaskItem.self) } ?? []
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
    func createTask(
        spaceId: String,
        title: String,
        notes: String?,
        createdBy: String,
        assignedTo: String,
        type: TaskType,
        dueAt: Date,
        priority: TaskPriority,
        tagIds: [String]
    ) async throws -> String {
        let now = Date()
        let taskRef = db.collection("spaces").document(spaceId).collection("tasks").document()
        let task = TaskItem(
            title: title,
            notes: notes,
            createdBy: createdBy,
            assignedTo: assignedTo,
            type: type,
            startAt: now,
            dueAt: dueAt,
            status: .open,
            priority: priority,
            tagIds: tagIds,
            hasAttachments: false,
            createdAt: now,
            updatedAt: now
        )
        try taskRef.setData(from: task)
        try await addEvent(spaceId: spaceId, taskId: taskRef.documentID, type: .created, byUid: createdBy, oldValue: nil, newValue: nil, reason: nil)
        return taskRef.documentID
    }

    func setStatus(spaceId: String, taskId: String, status: TaskStatus, byUid: String) async throws {
        let taskRef = db.collection("spaces").document(spaceId).collection("tasks").document(taskId)
        let snapshot = try await taskRef.getDocument()
        let oldStatus = snapshot.data()?["status"] as? String
        try await taskRef.updateData(["status": status.rawValue, "updatedAt": Date()])
        try await addEvent(spaceId: spaceId, taskId: taskId, type: .statusChanged, byUid: byUid, oldValue: oldStatus, newValue: status.rawValue, reason: nil)
    }

    func rescheduleDueAt(spaceId: String, taskId: String, newDueAt: Date, reason: String, byUid: String) async throws {
        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TaskRepositoryError.reasonRequired
        }
        let taskRef = db.collection("spaces").document(spaceId).collection("tasks").document(taskId)
        let snapshot = try await taskRef.getDocument()
        let oldDueAt = (snapshot.data()?["dueAt"] as? Timestamp)?.dateValue()
        try await taskRef.updateData(["dueAt": Timestamp(date: newDueAt), "updatedAt": Date()])
        try await addEvent(
            spaceId: spaceId,
            taskId: taskId,
            type: .dateChanged,
            byUid: byUid,
            oldValue: oldDueAt.map { ISO8601DateFormatter().string(from: $0) },
            newValue: ISO8601DateFormatter().string(from: newDueAt),
            reason: reason
        )
    }

    func deleteTask(spaceId: String, taskId: String) async throws {
        let taskRef = db.collection("spaces").document(spaceId).collection("tasks").document(taskId)
        let storage = Storage.storage()

        let attachmentsSnapshot = try await taskRef.collection("attachments").getDocuments()
        for doc in attachmentsSnapshot.documents {
            if let path = doc.data()["storagePath"] as? String {
                try? await storage.reference(withPath: path).delete()
            }
            try await doc.reference.delete()
        }

        let commentsSnapshot = try await taskRef.collection("comments").getDocuments()
        for doc in commentsSnapshot.documents {
            try await doc.reference.delete()
        }

        let eventsSnapshot = try await taskRef.collection("events").getDocuments()
        for doc in eventsSnapshot.documents {
            try await doc.reference.delete()
        }

        try await taskRef.delete()
    }

    private func addEvent(
        spaceId: String,
        taskId: String,
        type: TaskEventType,
        byUid: String,
        oldValue: String?,
        newValue: String?,
        reason: String?
    ) async throws {
        let event = TaskEvent(type: type, byUid: byUid, oldValue: oldValue, newValue: newValue, reason: reason, createdAt: Date())
        let eventRef = db.collection("spaces").document(spaceId).collection("tasks").document(taskId).collection("events").document()
        try eventRef.setData(from: event)
    }
}
