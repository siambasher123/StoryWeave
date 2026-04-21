import Foundation

struct ChatMessage: Codable, Identifiable, Sendable {
    let id: String
    var conversationID: String
    var senderUID: String
    var senderName: String
    var body: String
    var timestamp: Date
    var inviteSessionID: String?
}
