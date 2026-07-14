import FirebaseFirestore
import FirebaseStorage
import Foundation
import UIKit

enum AttachmentError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        "Не удалось обработать изображение."
    }
}

@MainActor
final class AttachmentRepository: ObservableObject {
    @Published var attachments: [Attachment] = []
    @Published var isUploading = false

    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func listen(spaceId: String, taskId: String) {
        listener?.remove()
        listener = db.collection("spaces").document(spaceId).collection("tasks").document(taskId).collection("attachments")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, _ in
                self?.attachments = snapshot?.documents.compactMap { try? $0.data(as: Attachment.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    deinit {
        listener?.remove()
    }

    func uploadAttachment(
        spaceId: String,
        taskId: String,
        image: UIImage,
        attachedTo: AttachmentParent,
        commentId: String?,
        uploadedBy: String
    ) async throws {
        guard let compressed = ImageCompressor.compress(image) else {
            throw AttachmentError.compressionFailed
        }

        isUploading = true
        defer { isUploading = false }

        let attachmentId = UUID().uuidString
        let storagePath = "spaces/\(spaceId)/tasks/\(taskId)/\(attachmentId).jpg"
        let storageRef = storage.reference(withPath: storagePath)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await storageRef.putDataAsync(compressed.data, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()

        let attachment = Attachment(
            attachedTo: attachedTo,
            commentId: commentId,
            storagePath: storagePath,
            downloadURL: downloadURL.absoluteString,
            contentType: "image/jpeg",
            sizeBytes: compressed.data.count,
            width: Int(compressed.size.width),
            height: Int(compressed.size.height),
            uploadedBy: uploadedBy,
            createdAt: Date()
        )

        let taskRef = db.collection("spaces").document(spaceId).collection("tasks").document(taskId)
        try taskRef.collection("attachments").document(attachmentId).setData(from: attachment)
        try await taskRef.updateData(["hasAttachments": true, "updatedAt": Date()])

        let event = TaskEvent(type: .attachmentAdded, byUid: uploadedBy, oldValue: nil, newValue: storagePath, reason: nil, createdAt: Date())
        try taskRef.collection("events").document().setData(from: event)
    }
}
