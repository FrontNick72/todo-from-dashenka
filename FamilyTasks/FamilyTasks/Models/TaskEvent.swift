import FirebaseFirestore

enum TaskEventType: String, Codable {
    case created
    case statusChanged = "status_changed"
    case dateChanged = "date_changed"
    case commented
    case attachmentAdded = "attachment_added"
}

struct TaskEvent: Codable, Identifiable {
    @DocumentID var id: String?
    var type: TaskEventType
    var byUid: String
    var oldValue: String?
    var newValue: String?
    var reason: String?
    var createdAt: Date
}
