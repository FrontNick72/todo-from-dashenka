import FirebaseFirestore

enum AttachmentParent: String, Codable {
    case task
    case comment
}

struct Attachment: Codable, Identifiable {
    @DocumentID var id: String?
    var attachedTo: AttachmentParent
    var commentId: String?
    var storagePath: String
    var downloadURL: String
    var contentType: String
    var sizeBytes: Int
    var width: Int?
    var height: Int?
    var uploadedBy: String
    var createdAt: Date
}
