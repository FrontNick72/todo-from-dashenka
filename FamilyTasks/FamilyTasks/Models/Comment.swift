import FirebaseFirestore

struct Comment: Codable, Identifiable {
    @DocumentID var id: String?
    var authorUid: String
    var text: String
    var createdAt: Date
}
