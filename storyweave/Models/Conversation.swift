import Foundation

/// Represents a conversation between two users in the chat system
/// Tracks participants, message history summary, and unread message counts
/// Conforms to Codable for Firestore persistence, Identifiable for SwiftUI lists,
/// Hashable for use in Sets and as dictionary keys
struct Conversation: Codable, Identifiable, Hashable, Sendable {
    // MARK: - Equatable & Hashable Conformance
    
    /// Conversations are equal if they have the same unique identifier
    /// Allows Conversation to be used in SwiftUI collections
    static func == (lhs: Conversation, rhs: Conversation) -> Bool { lhs.id == rhs.id }
    
    /// Hash implementation for Set and dictionary storage
    /// Uses only the ID to ensure consistency with equality semantics
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    // MARK: - Properties
    
    /// Unique conversation identifier, typically a pair ID combining both participants' UIDs
    /// Used as the Firestore document ID
    let id: String                          // pairID
    
    /// UIDs of both participants in the conversation
    /// Always contains exactly 2 user IDs for 1-to-1 conversations
    var participantUIDs: [String]
    
    /// Mapping of participant UID to their display name
    /// Used for quick access without separate name lookup
    /// Key: user UID, Value: user's display name
    var participantNames: [String: String]  // uid → displayName
    
    /// Text content of the most recent message in the conversation
    /// Used for conversation list preview
    var lastMessageBody: String
    
    /// UID of the participant who sent the most recent message
    /// Determines message direction in the preview
    var lastMessageSenderUID: String
    
    /// Timestamp of the most recent message
    /// Used for sorting conversations in the list (most recent first)
    var lastMessageTimestamp: Date
    
    /// Unread message count per participant
    /// Allows each user to have independent unread status
    /// Key: user UID, Value: count of unread messages from the other participant
    var unreadCounts: [String: Int]         // uid → unread count

    // MARK: - Helper Methods
    
    /// Gets the display name of the other participant in this conversation
    /// - Parameter myUID: The current user's UID
    /// - Returns: The other participant's display name, or "Unknown" if not found
    func peerName(for myUID: String) -> String {
        participantNames.first(where: { $0.key != myUID })?.value ?? "Unknown"
    }

    /// Gets the UID of the other participant in this conversation
    /// - Parameter myUID: The current user's UID
    /// - Returns: The other participant's UID, or empty string if not found
    func peerUID(for myUID: String) -> String {
        participantUIDs.first(where: { $0 != myUID }) ?? ""
    }

    /// Gets the unread message count for a specific participant
    /// - Parameter uid: The participant's UID
    /// - Returns: Number of unread messages, or 0 if not found
    func unread(for uid: String) -> Int { unreadCounts[uid] ?? 0 }
}
