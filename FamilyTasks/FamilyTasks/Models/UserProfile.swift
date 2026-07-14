import FirebaseFirestore

struct UserProfile: Codable {
    @DocumentID var id: String?
    var displayName: String
    var email: String
    var fcmTokens: [String]
    var spaceId: String?
    var createdAt: Date
}
