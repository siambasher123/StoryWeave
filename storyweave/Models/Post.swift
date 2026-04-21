import Foundation

struct Post: Codable, Identifiable, Sendable {
    let id: String
    var authorUID: String
    var authorName: String
    var body: String
    var imageURL: String?
    var attachedCharacterID: String?
    var attachedSkillID: String?
    var timestamp: Date
    var likeCount: Int
}
