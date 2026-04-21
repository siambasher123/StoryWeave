import Foundation
@preconcurrency import FirebaseFirestore
import FirebaseAuth

/// Central service for all Firestore database operations
/// Provides methods for CRUD operations on users, posts, conversations, game data, and custom stories
/// Ensures all database access is thread-safe and persists data with offline caching
@MainActor
final class FirestoreService {
    /// Shared singleton instance for app-wide database access
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    /// Initializes Firestore with persistent offline caching enabled
    /// Allows the app to work offline and sync when connectivity returns
    private init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }

    // MARK: - UserProfile
    /// Operations for user profile management

    /// Creates a new user profile in the database
    /// - Parameter profile: UserProfile object to save
    /// - Throws: Firestore encoding/writing errors
    func createUserProfile(_ profile: UserProfile) throws {
        try db.collection("users").document(profile.id).setData(from: profile)
    }

    /// Fetches a user profile by UID
    /// - Parameter uid: The user's unique identifier
    /// - Returns: UserProfile if found, nil otherwise
    /// - Throws: Firestore decoding errors
    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try doc.data(as: UserProfile.self)
    }

    /// Updates an existing user profile (merge, not replace)
    /// - Parameter profile: Updated UserProfile object
    /// - Throws: Firestore encoding/writing errors
    func updateUserProfile(_ profile: UserProfile) throws {
        try db.collection("users").document(profile.id).setData(from: profile, merge: true)
    }

    // MARK: - Characters
    /// Operations for game character management

    /// Fetches all available characters in the game
    /// - Returns: Array of all Character objects
    /// - Throws: Firestore query/decoding errors
    func fetchAllCharacters() async throws -> [Character] {
        let snap = try await db.collection("characters").getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Character.self) }
    }

    /// Fetches a specific character by ID
    /// - Parameter id: Character unique identifier
    /// - Returns: Character if found, nil otherwise
    /// - Throws: Firestore decoding errors
    func fetchCharacter(id: String) async throws -> Character? {
        let doc = try await db.collection("characters").document(id).getDocument()
        return try doc.data(as: Character.self)
    }

    /// Creates a new character (admin/system operation)
    /// - Parameter character: Character object to save
    /// - Throws: Firestore encoding/writing errors
    func createCharacter(_ character: Character) throws {
        try db.collection("characters").document(character.id).setData(from: character)
    }

    // MARK: - Skills
    /// Operations for game skill management

    /// Fetches all available skills in the game
    /// - Returns: Array of all Skill objects
    /// - Throws: Firestore query/decoding errors
    func fetchAllSkills() async throws -> [Skill] {
        let snap = try await db.collection("skills").getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Skill.self) }
    }

    /// Fetches a specific skill by ID
    /// - Parameter id: Skill unique identifier
    /// - Returns: Skill if found, nil otherwise
    /// - Throws: Firestore decoding errors
    func fetchSkill(id: String) async throws -> Skill? {
        let doc = try await db.collection("skills").document(id).getDocument()
        return try doc.data(as: Skill.self)
    }

    /// Creates a new skill (admin/system operation)
    /// - Parameter skill: Skill object to save
    /// - Throws: Firestore encoding/writing errors
    func createSkill(_ skill: Skill) throws {
        try db.collection("skills").document(skill.id).setData(from: skill)
    }

    // MARK: - Posts
    /// Operations for social feed and post management

    /// Creates a real-time stream of all posts ordered by recency
    /// - Returns: AsyncStream that yields updated post arrays when posts change
    func postsStream() -> AsyncStream<[Post]> {
        let db = Firestore.firestore()
        return AsyncStream { continuation in
            let listener = db.collection("posts")
                .order(by: "timestamp", descending: true)
                .addSnapshotListener { snap, _ in
                    let posts = (snap?.documents ?? []).compactMap { try? $0.data(as: Post.self) }
                    Task { @MainActor in continuation.yield(posts) }
                }
            let listenerBox = _FSendableBox(listener)
            continuation.onTermination = { _ in listenerBox.value.remove() }
        }
    }

    /// Creates a new post on the social feed
    /// - Parameter post: Post object to save
    /// - Throws: Firestore encoding/writing errors
    func createPost(_ post: Post) throws {
        try db.collection("posts").document(post.id).setData(from: post)
    }

    /// Toggles a user's like on a post (like/unlike)
    /// Updates both the post's like count and the likers collection
    /// - Parameters:
    ///   - postID: ID of the post to like/unlike
    ///   - uid: User's unique identifier
    ///   - currentlyLiked: true if unliking (toggle off), false if liking (toggle on)
    /// - Throws: Firestore update/delete errors
    func toggleLike(postID: String, uid: String, currentlyLiked: Bool) async throws {
        let delta: Int64 = currentlyLiked ? -1 : 1
        try await db.collection("posts").document(postID)
            .updateData(["likeCount": FieldValue.increment(delta)])
        let likerRef = db.collection("postLikes").document(postID)
            .collection("likers").document(uid)
        if currentlyLiked {
            try await likerRef.delete()
        } else {
            try await likerRef.setData(["uid": uid])
        }
    }

    /// Checks if a user has liked a specific post
    /// - Parameters:
    ///   - postID: ID of the post to check
    ///   - uid: User's unique identifier
    /// - Returns: true if user has liked the post, false otherwise
    /// - Throws: Firestore query errors
    func isPostLiked(postID: String, uid: String) async throws -> Bool {
        let doc = try await db.collection("postLikes").document(postID)
            .collection("likers").document(uid).getDocument()
        return doc.exists
    }

    // MARK: - Reactions
    /// Operations for emoji reactions on posts

    /// Adds or updates an emoji reaction to a post from a user
    /// - Parameters:
    ///   - postID: ID of the post being reacted to
    ///   - emoji: Emoji character to react with
    ///   - uid: User's unique identifier
    ///   - displayName: User's display name for context
    /// - Throws: Firestore encoding/writing errors
    func react(postID: String, emoji: String, uid: String, displayName: String) throws {
        let reaction = Reaction(id: uid, postID: postID, uid: uid,
                                displayName: displayName, emoji: emoji, timestamp: Date())
        try db.collection("posts").document(postID)
            .collection("reactions").document(uid).setData(from: reaction)
    }

    /// Removes a user's emoji reaction from a post
    /// - Parameters:
    ///   - postID: ID of the post
    ///   - uid: User's unique identifier
    /// - Throws: Firestore delete errors
    func removeReaction(postID: String, uid: String) async throws {
        try await db.collection("posts").document(postID)
            .collection("reactions").document(uid).delete()
    }

    /// Creates a real-time stream of all reactions on a specific post
    /// - Parameter postID: ID of the post
    /// - Returns: AsyncStream that yields updated reaction arrays when reactions change
    func reactionsStream(postID: String) -> AsyncStream<[Reaction]> {
        let db = Firestore.firestore()
        return AsyncStream { continuation in
            let listener = db.collection("posts").document(postID)
                .collection("reactions")
                .addSnapshotListener { snap, _ in
                    let reactions = (snap?.documents ?? []).compactMap { try? $0.data(as: Reaction.self) }
                    Task { @MainActor in continuation.yield(reactions) }
                }
            let box = _FSendableBox(listener)
            continuation.onTermination = { _ in box.value.remove() }
        }
    }

    // MARK: - Comments
    /// Operations for post comments

    /// Adds a comment to a post
    /// - Parameter comment: Comment object to save
    /// - Throws: Firestore encoding/writing errors
    func addComment(_ comment: Comment) throws {
        try db.collection("posts").document(comment.postID)
            .collection("comments").document(comment.id).setData(from: comment)
    }

    /// Creates a real-time stream of comments on a post ordered by timestamp
    /// - Parameter postID: ID of the post
    /// - Returns: AsyncStream that yields updated comment arrays when comments change
    func commentsStream(postID: String) -> AsyncStream<[Comment]> {
        let db = Firestore.firestore()
        return AsyncStream { continuation in
            let listener = db.collection("posts").document(postID)
                .collection("comments")
                .order(by: "timestamp")
                .addSnapshotListener { snap, _ in
                    let comments = (snap?.documents ?? []).compactMap { try? $0.data(as: Comment.self) }
                    Task { @MainActor in continuation.yield(comments) }
                }
            let box = _FSendableBox(listener)
            continuation.onTermination = { _ in box.value.remove() }
        }
    }

    // MARK: - GameState
    /// Operations for saving and loading game progress

    /// Saves the current game state for a user
    /// - Parameters:
    ///   - state: GameState object containing all game progress
    ///   - uid: User's unique identifier
    /// - Throws: Firestore encoding/writing errors
    func saveGameState(_ state: GameState, for uid: String) throws {
        try db.collection("gameSaves").document(uid).setData(from: state)
    }

    /// Loads a user's saved game state
    /// - Parameter uid: User's unique identifier
    /// - Returns: GameState if saved previously, nil if no save exists
    /// - Throws: Firestore decoding errors
    func loadGameState(uid: String) async throws -> GameState? {
        let doc = try await db.collection("gameSaves").document(uid).getDocument()
        return try doc.data(as: GameState.self)
    }

    // MARK: - Chat
    /// Operations for user connections, conversations, and real-time messaging

    /// Generates a consistent pair ID from two user IDs
    /// Sorting ensures same ID regardless of input order (uid1, uid2) or (uid2, uid1)
    /// - Parameters:
    ///   - uid1: First user's unique identifier
    ///   - uid2: Second user's unique identifier
    /// - Returns: Unique pair identifier string
    static func pairID(_ uid1: String, _ uid2: String) -> String {
        [uid1, uid2].sorted().joined(separator: "_")
    }

    /// Fetches up to 100 user profiles for user discovery/search
    /// - Parameter excludingUID: User ID to exclude (typically current user)
    /// - Returns: Array of UserProfile objects
    /// - Throws: Firestore query/decoding errors
    func fetchAllUsers(excludingUID: String) async throws -> [UserProfile] {
        let snap = try await db.collection("users").limit(to: 100).getDocuments()
        return snap.documents.compactMap { try? $0.data(as: UserProfile.self) }
            .filter { $0.id != excludingUID }
    }

    /// Searches for users by display name prefix (live search)
    /// Uses Firestore range queries for efficient prefix matching
    /// - Parameters:
    ///   - prefix: Display name prefix to search for
    ///   - excludingUID: User ID to exclude from results
    /// - Returns: Array of matching UserProfile objects (up to 20)
    /// - Throws: Firestore query/decoding errors
    func searchUsers(prefix: String, excludingUID: String) async throws -> [UserProfile] {
        guard !prefix.isEmpty else { return [] }
        let snap = try await db.collection("users")
            .whereField("displayName", isGreaterThanOrEqualTo: prefix)
            .whereField("displayName", isLessThan: prefix + "\u{f8ff}")
            .limit(to: 20)
            .getDocuments()
        return try snap.documents.compactMap { try? $0.data(as: UserProfile.self) }
            .filter { $0.id != excludingUID }
    }

    /// Sends a connection request (friend request) from one user to another
    /// Creates a Connection document with pending status
    /// - Parameters:
    ///   - fromUID: Requesting user's ID
    ///   - fromName: Requesting user's display name
    ///   - toUID: Recipient user's ID
    ///   - toName: Recipient user's display name
    /// - Throws: Firestore encoding/writing errors
    func sendConnectionRequest(from fromUID: String, fromName: String,
                               to toUID: String, toName: String) async throws {
        let pid = Self.pairID(fromUID, toUID)
        let conn = Connection(
            id: pid, fromUID: fromUID, fromName: fromName,
            toUID: toUID, toName: toName,
            status: .pending, participants: [fromUID, toUID],
            createdAt: Date()
        )
        try db.collection("connections").document(pid).setData(from: conn)
    }

    /// Responds to a connection request (accept or decline)
    /// - Parameters:
    ///   - pairID: The connection pair ID
    ///   - accept: true to accept, false to decline
    /// - Throws: Firestore update errors
    func respondToConnection(pairID: String, accept: Bool) async throws {
        let status: ConnectionStatus = accept ? .accepted : .declined
        try await db.collection("connections").document(pairID)
            .updateData(["status": status.rawValue])
    }

    /// Creates a real-time stream of all connection requests for a user
    /// Includes pending, accepted, and declined connection statuses
    /// - Parameter uid: User's unique identifier
    /// - Returns: AsyncStream that yields updated connection arrays when connections change
    func connectionsStream(uid: String) -> AsyncStream<[Connection]> {
        AsyncStream { continuation in
            let listener = db.collection("connections")
                .whereField("participants", arrayContains: uid)
                .addSnapshotListener { snap, _ in
                    let conns = (snap?.documents ?? []).compactMap { try? $0.data(as: Connection.self) }
                    Task { @MainActor in continuation.yield(conns) }
                }
            let box = _FSendableBox(listener)
            continuation.onTermination = { _ in box.value.remove() }
        }
    }

    /// Creates a real-time stream of all conversations for a user
    /// Conversation documents are updated whenever new messages arrive
    /// - Parameter uid: User's unique identifier
    /// - Returns: AsyncStream that yields updated conversation arrays when conversations change
    func conversationsStream(uid: String) -> AsyncStream<[Conversation]> {
        AsyncStream { continuation in
            let listener = db.collection("conversations")
                .whereField("participantUIDs", arrayContains: uid)
                .addSnapshotListener { snap, _ in
                    let convs = (snap?.documents ?? []).compactMap { try? $0.data(as: Conversation.self) }
                    Task { @MainActor in continuation.yield(convs) }
                }
            let box = _FSendableBox(listener)
            continuation.onTermination = { _ in box.value.remove() }
        }
    }

    /// Creates a conversation document if it doesn't already exist
    /// Safe to call multiple times - only creates once
    /// - Parameter conversation: Conversation object to create
    /// - Throws: Firestore check/write errors
    func ensureConversation(_ conversation: Conversation) async throws {
        let ref = db.collection("conversations").document(conversation.id)
        let doc = try await ref.getDocument()
        if !doc.exists { try ref.setData(from: conversation) }
    }

    /// Sends a message in a conversation and updates the conversation's metadata
    /// Updates lastMessage fields and increments unread count for recipient
    /// - Parameters:
    ///   - message: ChatMessage object to send
    ///   - conversation: The conversation context
    /// - Throws: Firestore write/update errors
    func sendMessage(_ message: ChatMessage, in conversation: Conversation) async throws {
        try db.collection("conversations").document(conversation.id)
            .collection("messages").document(message.id).setData(from: message)
        let otherUID = conversation.participantUIDs.first(where: { $0 != message.senderUID }) ?? ""
        try await db.collection("conversations").document(conversation.id).updateData([
            "lastMessageBody": message.body,
            "lastMessageSenderUID": message.senderUID,
            "lastMessageTimestamp": Timestamp(date: message.timestamp),
            "unreadCounts.\(otherUID)": FieldValue.increment(Int64(1))
        ])
    }

    /// Creates a real-time stream of messages in a conversation ordered by timestamp
    /// - Parameter conversationID: ID of the conversation
    /// - Returns: AsyncStream that yields updated message arrays when new messages arrive
    func messagesStream(conversationID: String) -> AsyncStream<[ChatMessage]> {
        AsyncStream { continuation in
            let listener = db.collection("conversations").document(conversationID)
                .collection("messages")
                .order(by: "timestamp")
                .addSnapshotListener { snap, _ in
                    let msgs = (snap?.documents ?? []).compactMap { try? $0.data(as: ChatMessage.self) }
                    Task { @MainActor in continuation.yield(msgs) }
                }
            let box = _FSendableBox(listener)
            continuation.onTermination = { _ in box.value.remove() }
        }
    }

    /// Marks all messages in a conversation as read for a user
    /// Sets that user's unread count to 0
    /// - Parameters:
    ///   - conversationID: ID of the conversation
    ///   - uid: User's unique identifier
    /// - Throws: Firestore update errors
    func markConversationRead(conversationID: String, uid: String) async throws {
        try await db.collection("conversations").document(conversationID)
            .updateData(["unreadCounts.\(uid)": 0])
    }

    // MARK: - User Stories
    /// Operations for user-created custom stories

    /// Saves or updates a user story
    /// - Parameter story: UserStory object to save
    /// - Throws: Firestore encoding/writing errors
    func saveUserStory(_ story: UserStory) throws {
        try db.collection("userStories").document(story.id).setData(from: story)
    }

    /// Fetches all stories created by a specific user
    /// - Parameter uid: Author's unique identifier
    /// - Returns: Array of UserStory objects created by the user
    /// - Throws: Firestore query/decoding errors
    func fetchMyStories(uid: String) async throws -> [UserStory] {
        let snap = try await db.collection("userStories")
            .whereField("authorUID", isEqualTo: uid)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: UserStory.self) }
    }

    /// Creates a real-time stream of all published stories sorted by popularity
    /// Only includes stories marked as isPublished = true
    /// - Returns: AsyncStream that yields published stories sorted by play count (descending)
    func publishedStoriesStream() -> AsyncStream<[UserStory]> {
        AsyncStream { continuation in
            let listener = db.collection("userStories")
                .whereField("isPublished", isEqualTo: true)
                .addSnapshotListener { snap, _ in
                    let stories = (snap?.documents ?? [])
                        .compactMap { try? $0.data(as: UserStory.self) }
                        .sorted { $0.playCount > $1.playCount }
                    Task { @MainActor in continuation.yield(stories) }
                }
            let box = _FSendableBox(listener)
            continuation.onTermination = { _ in box.value.remove() }
        }
    }

    /// Increments the play count of a story
    /// Called when a user starts playing a story
    /// - Parameter storyID: ID of the story
    /// - Throws: Firestore update errors
    func incrementPlayCount(storyID: String) async throws {
        try await db.collection("userStories").document(storyID)
            .updateData(["playCount": FieldValue.increment(Int64(1))])
    }

    /// Deletes a user story completely
    /// - Parameter id: ID of the story to delete
    /// - Throws: Firestore delete errors
    func deleteUserStory(id: String) async throws {
        try await db.collection("userStories").document(id).delete()
    }

    // MARK: - Game Sessions
    /// Operations for multiplayer game session management

    /// Creates a new game session
    /// - Parameter session: GameSession object to create
    /// - Throws: Firestore encoding/writing errors
    func createGameSession(_ session: GameSession) throws {
        try db.collection("gameSessions").document(session.id).setData(from: session)
    }

    /// Creates a real-time stream of a single game session
    /// Used for multiplayer synchronization during active gameplay
    /// - Parameter sessionID: ID of the game session
    /// - Returns: AsyncStream that yields the session when it changes
    func gameSessionStream(sessionID: String) -> AsyncStream<GameSession?> {
        AsyncStream { continuation in
            let listener = db.collection("gameSessions").document(sessionID)
                .addSnapshotListener { snap, _ in
                    let session = try? snap?.data(as: GameSession.self)
                    Task { @MainActor in continuation.yield(session) }
                }
            let box = _FSendableBox(listener)
            continuation.onTermination = { _ in box.value.remove() }
        }
    }

    /// Updates an existing game session (merge, not replace)
    /// - Parameter session: Updated GameSession object
    /// - Throws: Firestore encoding/writing errors
    func updateGameSession(_ session: GameSession) throws {
        try db.collection("gameSessions").document(session.id).setData(from: session, merge: true)
    }

    /// Updates a player's ready status and selected character for a session
    /// Called when player selects a character and confirms ready in lobby
    /// - Parameters:
    ///   - sessionID: ID of the game session
    ///   - uid: Player's unique identifier
    ///   - characterID: ID of the selected character
    ///   - isReady: true if player is ready to start
    /// - Throws: Firestore read/write errors
    func updatePlayerReady(sessionID: String, uid: String, characterID: String, isReady: Bool) async throws {
        let snap = try await db.collection("gameSessions").document(sessionID).getDocument()
        guard var session = try? snap.data(as: GameSession.self),
              let idx = session.players.firstIndex(where: { $0.id == uid }) else { return }
        session.players[idx].characterID = characterID
        session.players[idx].isReady = isReady
        session.players[idx].status = .joined
        try db.collection("gameSessions").document(sessionID).setData(from: session)
    }

    /// Submits a player action (serialized as JSON) for game resolution
    /// Action is stored temporarily until the DM/engine resolves it
    /// - Parameters:
    ///   - sessionID: ID of the game session
    ///   - actionJSON: Serialized action JSON string
    /// - Throws: Firestore update errors
    func submitAction(sessionID: String, actionJSON: String) async throws {
        try await db.collection("gameSessions").document(sessionID)
            .updateData(["pendingActionJSON": actionJSON])
    }

    /// Resolves a player action and updates the session state
    /// Updates combat snapshot, turn index, and clears pending action
    /// - Parameters:
    ///   - sessionID: ID of the game session
    ///   - snapshot: Updated combat state after action resolution
    ///   - nextTurnUID: UID of next player to take a turn, nil if turn ends
    ///   - turnIndex: Current turn number
    /// - Throws: Firestore encoding/update errors
    func resolveAction(sessionID: String, snapshot: CombatSnapshot,
                       nextTurnUID: String?, turnIndex: Int) async throws {
        var data: [String: Any] = [
            "combatSnapshot": try Firestore.Encoder().encode(snapshot),
            "currentTurnIndex": turnIndex,
            "pendingActionJSON": FieldValue.delete()
        ]
        if let uid = nextTurnUID { data["currentTurnUID"] = uid }
        else { data["currentTurnUID"] = FieldValue.delete() }
        try await db.collection("gameSessions").document(sessionID).updateData(data)
    }

    /// Broadcasts narration and game state updates to all players in a session
    /// Called when game progress is made (scene change, story advancement)
    /// - Parameters:
    ///   - sessionID: ID of the game session
    ///   - narration: Narrative text to display to players
    ///   - gameState: Current game state with all progress
    /// - Throws: Firestore encoding/update errors
    func broadcastNarration(sessionID: String, narration: String, gameState: GameState) async throws {
        let encodedState = try Firestore.Encoder().encode(gameState)
        try await db.collection("gameSessions").document(sessionID).updateData([
            "currentNarration": narration,
            "gameState": encodedState
        ])
    }

    /// Creates a real-time stream of game sessions a user is invited to
    /// Only includes sessions in lobby or playing status
    /// - Parameter uid: User's unique identifier
    /// - Returns: AsyncStream that yields available sessions a user can join
    func myInvitedSessionsStream(uid: String) -> AsyncStream<[GameSession]> {
        AsyncStream { continuation in
            let listener = db.collection("gameSessions")
                .whereField("invitedUIDs", arrayContains: uid)
                .addSnapshotListener { snap, _ in
                    let sessions = (snap?.documents ?? [])
                        .compactMap { try? $0.data(as: GameSession.self) }
                        .filter { $0.status == .lobby || $0.status == .playing }
                    Task { @MainActor in continuation.yield(sessions) }
                }
            let box = _FSendableBox(listener)
            continuation.onTermination = { _ in box.value.remove() }
        }
    }

    /// Marks a session as abandoned (player left mid-game)
    /// - Parameter id: ID of the game session
    /// - Throws: Firestore update errors
    func abandonSession(id: String) async throws {
        try await db.collection("gameSessions").document(id)
            .updateData(["status": SessionStatus.abandoned.rawValue])
    }

    // MARK: - CRUD extensions

    func deletePost(postID: String) async throws {
        try await db.collection("posts").document(postID).delete()
    }

    func updatePost(_ post: Post) throws {
        try db.collection("posts").document(post.id).setData(from: post, merge: true)
    }

    func updateCharacter(_ character: Character) throws {
        try db.collection("characters").document(character.id).setData(from: character, merge: true)
    }

    func deleteCharacter(characterID: String) async throws {
        try await db.collection("characters").document(characterID).delete()
    }

    func updateSkill(_ skill: Skill) throws {
        try db.collection("skills").document(skill.id).setData(from: skill, merge: true)
    }

    func deleteSkill(skillID: String) async throws {
        try await db.collection("skills").document(skillID).delete()
    }

    func deleteComment(commentID: String, postID: String) async throws {
        try await db.collection("posts").document(postID)
            .collection("comments").document(commentID).delete()
    }

    func updateComment(_ comment: Comment) throws {
        try db.collection("posts").document(comment.postID)
            .collection("comments").document(comment.id).setData(from: comment, merge: true)
    }

    func deleteMessage(messageID: String, conversationID: String) async throws {
        try await db.collection("conversations").document(conversationID)
            .collection("messages").document(messageID).delete()
    }

    func updateMessage(_ message: ChatMessage) throws {
        try db.collection("conversations").document(message.conversationID)
            .collection("messages").document(message.id).setData(from: message, merge: true)
    }

    // MARK: - Seeding defaults
    /// Operations for initial database seeding with game content

    /// Ensures default game content (characters, skills) are seeded into Firestore
    /// Only seeds once using a sentinel document to prevent re-seeding
    func ensureDefaultsSeeded() async {
        let sentinel = db.collection("meta").document("seed_v1")
        guard let doc = try? await sentinel.getDocument(), !doc.exists else { return }
        for char in DefaultContent.defaultCharacters {
            try? createCharacter(char)
        }
        for skill in DefaultContent.defaultSkills {
            try? createSkill(skill)
        }
        try? await sentinel.setData(["seeded": true])
    }
}

/// Helper wrapper for Firestore snapshot listeners
/// Converts non-Sendable listeners to Sendable for use in async streams
/// Uses unsafe marking because listeners are only accessed on MainActor
private final class _FSendableBox<T>: @unchecked Sendable {
    nonisolated(unsafe) let value: T
    init(_ value: T) { self.value = value }
}
