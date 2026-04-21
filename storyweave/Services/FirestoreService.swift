import Foundation
@preconcurrency import FirebaseFirestore
import FirebaseAuth

@MainActor
final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        db.settings = settings
    }

    // MARK: - UserProfile

    func createUserProfile(_ profile: UserProfile) throws {
        try db.collection("users").document(profile.id).setData(from: profile)
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(uid).getDocument()
        return try doc.data(as: UserProfile.self)
    }

    func updateUserProfile(_ profile: UserProfile) throws {
        try db.collection("users").document(profile.id).setData(from: profile, merge: true)
    }

    // MARK: - Characters

    func fetchAllCharacters() async throws -> [Character] {
        let snap = try await db.collection("characters").getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Character.self) }
    }

    func fetchCharacter(id: String) async throws -> Character? {
        let doc = try await db.collection("characters").document(id).getDocument()
        return try doc.data(as: Character.self)
    }

    func createCharacter(_ character: Character) throws {
        try db.collection("characters").document(character.id).setData(from: character)
    }

    // MARK: - Skills

    func fetchAllSkills() async throws -> [Skill] {
        let snap = try await db.collection("skills").getDocuments()
        return try snap.documents.compactMap { try $0.data(as: Skill.self) }
    }

    func fetchSkill(id: String) async throws -> Skill? {
        let doc = try await db.collection("skills").document(id).getDocument()
        return try doc.data(as: Skill.self)
    }

    func createSkill(_ skill: Skill) throws {
        try db.collection("skills").document(skill.id).setData(from: skill)
    }

    // MARK: - Posts

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

    func createPost(_ post: Post) throws {
        try db.collection("posts").document(post.id).setData(from: post)
    }

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

    func isPostLiked(postID: String, uid: String) async throws -> Bool {
        let doc = try await db.collection("postLikes").document(postID)
            .collection("likers").document(uid).getDocument()
        return doc.exists
    }

    // MARK: - Reactions

    func react(postID: String, emoji: String, uid: String, displayName: String) throws {
        let reaction = Reaction(id: uid, postID: postID, uid: uid,
                                displayName: displayName, emoji: emoji, timestamp: Date())
        try db.collection("posts").document(postID)
            .collection("reactions").document(uid).setData(from: reaction)
    }

    func removeReaction(postID: String, uid: String) async throws {
        try await db.collection("posts").document(postID)
            .collection("reactions").document(uid).delete()
    }

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

    func addComment(_ comment: Comment) throws {
        try db.collection("posts").document(comment.postID)
            .collection("comments").document(comment.id).setData(from: comment)
    }

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

    func saveGameState(_ state: GameState, for uid: String) throws {
        try db.collection("gameSaves").document(uid).setData(from: state)
    }

    func loadGameState(uid: String) async throws -> GameState? {
        let doc = try await db.collection("gameSaves").document(uid).getDocument()
        return try doc.data(as: GameState.self)
    }

    // MARK: - Chat

    static func pairID(_ uid1: String, _ uid2: String) -> String {
        [uid1, uid2].sorted().joined(separator: "_")
    }

    func fetchAllUsers(excludingUID: String) async throws -> [UserProfile] {
        let snap = try await db.collection("users").limit(to: 100).getDocuments()
        return snap.documents.compactMap { try? $0.data(as: UserProfile.self) }
            .filter { $0.id != excludingUID }
    }

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

    func respondToConnection(pairID: String, accept: Bool) async throws {
        let status: ConnectionStatus = accept ? .accepted : .declined
        try await db.collection("connections").document(pairID)
            .updateData(["status": status.rawValue])
    }

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

    func ensureConversation(_ conversation: Conversation) async throws {
        let ref = db.collection("conversations").document(conversation.id)
        let doc = try await ref.getDocument()
        if !doc.exists { try ref.setData(from: conversation) }
    }

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

    func markConversationRead(conversationID: String, uid: String) async throws {
        try await db.collection("conversations").document(conversationID)
            .updateData(["unreadCounts.\(uid)": 0])
    }

    // MARK: - User Stories

    func saveUserStory(_ story: UserStory) throws {
        try db.collection("userStories").document(story.id).setData(from: story)
    }

    func fetchMyStories(uid: String) async throws -> [UserStory] {
        let snap = try await db.collection("userStories")
            .whereField("authorUID", isEqualTo: uid)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: UserStory.self) }
    }

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

    func incrementPlayCount(storyID: String) async throws {
        try await db.collection("userStories").document(storyID)
            .updateData(["playCount": FieldValue.increment(Int64(1))])
    }

    func deleteUserStory(id: String) async throws {
        try await db.collection("userStories").document(id).delete()
    }

    // MARK: - Game Sessions

    func createGameSession(_ session: GameSession) throws {
        try db.collection("gameSessions").document(session.id).setData(from: session)
    }

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

    func updateGameSession(_ session: GameSession) throws {
        try db.collection("gameSessions").document(session.id).setData(from: session, merge: true)
    }

    func updatePlayerReady(sessionID: String, uid: String, characterID: String, isReady: Bool) async throws {
        let snap = try await db.collection("gameSessions").document(sessionID).getDocument()
        guard var session = try? snap.data(as: GameSession.self),
              let idx = session.players.firstIndex(where: { $0.id == uid }) else { return }
        session.players[idx].characterID = characterID
        session.players[idx].isReady = isReady
        session.players[idx].status = .joined
        try db.collection("gameSessions").document(sessionID).setData(from: session)
    }

    func submitAction(sessionID: String, actionJSON: String) async throws {
        try await db.collection("gameSessions").document(sessionID)
            .updateData(["pendingActionJSON": actionJSON])
    }

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

    func broadcastNarration(sessionID: String, narration: String, gameState: GameState) async throws {
        let encodedState = try Firestore.Encoder().encode(gameState)
        try await db.collection("gameSessions").document(sessionID).updateData([
            "currentNarration": narration,
            "gameState": encodedState
        ])
    }

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

private final class _FSendableBox<T>: @unchecked Sendable {
    nonisolated(unsafe) let value: T
    init(_ value: T) { self.value = value }
}
