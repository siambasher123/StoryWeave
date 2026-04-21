import Foundation

struct UserProfile: Codable, Identifiable, Sendable {
    let id: String
    var displayName: String
    var avatarURL: String?
    var createdAt: Date
    var gameStats: GameAnalytics
}
