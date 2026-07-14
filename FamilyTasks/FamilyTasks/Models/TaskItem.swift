import FirebaseFirestore

enum TaskType: String, Codable {
    case scheduled
    case deadline
}

enum TaskStatus: String, Codable {
    case open
    case completed
    case declined
}

enum TaskPriority: String, Codable {
    case low
    case normal
    case high
}

struct TaskItem: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var notes: String?
    var createdBy: String
    var assignedTo: String
    var type: TaskType
    var startAt: Date
    var dueAt: Date
    var status: TaskStatus
    var priority: TaskPriority
    var tagIds: [String]
    var hasAttachments: Bool
    var createdAt: Date
    var updatedAt: Date
}
