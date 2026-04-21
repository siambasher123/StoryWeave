import SwiftUI
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var connections: [Connection] = []      // accepted
    @Published var pendingIncoming: [Connection] = [] // pending & toUID == me
    @Published var pendingOutgoing: [Connection] = [] // pending & fromUID == me
    @Published var allUsers: [UserProfile] = []
    @Published var isSearching = false

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private var convTask: Task<Void, Never>?
    private var connTask: Task<Void, Never>?

    var myUID: String? { auth.currentUserID }

    var totalUnread: Int {
        guard let uid = myUID else { return 0 }
        return conversations.reduce(0) { $0 + $1.unread(for: uid) }
    }

    func load() async {
        guard let uid = myUID else { return }
        convTask?.cancel()
        connTask?.cancel()

        allUsers = (try? await firestore.fetchAllUsers(excludingUID: uid)) ?? []

        convTask = Task {
            for await convs in firestore.conversationsStream(uid: uid) {
                guard !Task.isCancelled else { break }
                conversations = convs.sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
            }
        }
        connTask = Task {
            for await conns in firestore.connectionsStream(uid: uid) {
                guard !Task.isCancelled else { break }
                connections     = conns.filter { $0.status == .accepted }
                pendingIncoming = conns.filter { $0.status == .pending && $0.toUID == uid }
                pendingOutgoing = conns.filter { $0.status == .pending && $0.fromUID == uid }
            }
        }
    }

    func stopListening() {
        convTask?.cancel()
        connTask?.cancel()
    }

    enum RelationshipState { case none, outgoingPending, incomingPending, connected }

    func relationship(with otherUID: String) -> RelationshipState {
        guard let uid = myUID else { return .none }
        let pid = FirestoreService.pairID(uid, otherUID)
        if connections.contains(where: { $0.id == pid })     { return .connected }
        if pendingIncoming.contains(where: { $0.id == pid }) { return .incomingPending }
        if pendingOutgoing.contains(where: { $0.id == pid }) { return .outgoingPending }
        return .none
    }

    func filteredUsers(query: String) -> [UserProfile] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return allUsers }
        return allUsers.filter { $0.displayName.localizedCaseInsensitiveContains(q) }
    }

    func sendRequest(to user: UserProfile) async {
        guard let uid = myUID,
              let me = try? await firestore.fetchUserProfile(uid: uid) else { return }
        try? await firestore.sendConnectionRequest(
            from: uid, fromName: me.displayName,
            to: user.id, toName: user.displayName
        )
    }

    func accept(_ connection: Connection) async {
        try? await firestore.respondToConnection(pairID: connection.id, accept: true)
    }

    func decline(_ connection: Connection) async {
        try? await firestore.respondToConnection(pairID: connection.id, accept: false)
    }

    func openConversation(with otherUID: String) async -> Conversation? {
        guard let uid = myUID else { return nil }
        let pid = FirestoreService.pairID(uid, otherUID)
        if let existing = conversations.first(where: { $0.id == pid }) { return existing }

        async let myTask    = firestore.fetchUserProfile(uid: uid)
        async let theirTask = firestore.fetchUserProfile(uid: otherUID)
        guard let mine = try? await myTask, let theirs = try? await theirTask else { return nil }

        let conv = Conversation(
            id: pid,
            participantUIDs: [uid, otherUID].sorted(),
            participantNames: [uid: mine.displayName, otherUID: theirs.displayName],
            lastMessageBody: "",
            lastMessageSenderUID: uid,
            lastMessageTimestamp: Date(),
            unreadCounts: [uid: 0, otherUID: 0]
        )
        try? await firestore.ensureConversation(conv)
        return conv
    }
}
