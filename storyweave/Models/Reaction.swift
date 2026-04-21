import Foundation

struct Reaction: Codable, Identifiable, Sendable {
    let id: String        // == uid (one reaction per user per post)
    let postID: String
    let uid: String
    let displayName: String
    let emoji: String
    let timestamp: Date
}
