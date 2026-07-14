import FirebaseFirestore

struct Tag: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var color: String
    var createdBy: String
    var createdAt: Date
}
