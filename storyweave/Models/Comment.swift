import Foundation

struct Comment: Codable, Identifiable, Sendable {
    let id: String
    let postID: String
    let parentCommentID: String?
    let authorUID: String
    let authorName: String
    var body: String
    let timestamp: Date
}
