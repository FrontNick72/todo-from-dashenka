import FirebaseFirestore

struct Space: Codable {
    @DocumentID var id: String?
    var memberUids: [String]
    var inviteCode: String
    var createdAt: Date
}
