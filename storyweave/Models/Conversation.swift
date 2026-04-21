import Foundation

struct Conversation: Codable, Identifiable, Hashable, Sendable {
    static func == (lhs: Conversation, rhs: Conversation) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: String                          // pairID
    var participantUIDs: [String]
    var participantNames: [String: String]  // uid → displayName
    var lastMessageBody: String
    var lastMessageSenderUID: String
    var lastMessageTimestamp: Date
    var unreadCounts: [String: Int]         // uid → unread count

    func peerName(for myUID: String) -> String {
        participantNames.first(where: { $0.key != myUID })?.value ?? "Unknown"
    }

    func peerUID(for myUID: String) -> String {
        participantUIDs.first(where: { $0 != myUID }) ?? ""
    }

    func unread(for uid: String) -> Int { unreadCounts[uid] ?? 0 }
}
