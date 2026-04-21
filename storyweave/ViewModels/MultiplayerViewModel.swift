import Combine
import Foundation
import FirebaseAuth

@MainActor
final class MultiplayerViewModel: ObservableObject {
    @Published var session: GameSession?
    @Published var localGameVM: GameViewModel = GameViewModel()
    @Published var mySessions: [GameSession] = []
    @Published var isLoading = false
    @Published var error: String?

    private var sessionStreamTask: Task<Void, Never>?
    private var mySessionsTask: Task<Void, Never>?

    var myUID: String { Auth.auth().currentUser?.uid ?? "" }
    var myName: String { Auth.auth().currentUser?.displayName ?? "Player" }

    var isHost: Bool { session?.hostUID == myUID }
    var isMyTurn: Bool { session?.currentTurnUID == myUID }

    var currentPlayer: SessionPlayer? {
        session?.players.first(where: { $0.id == myUID })
    }

    var allReady: Bool {
        guard let session else { return false }
        return session.players.count >= 2
            && session.players.allSatisfy { $0.isReady && !$0.characterID.isEmpty }
    }

    // MARK: — Session lifecycle

    func createSession() async {
        isLoading = true
        var newSession = GameSession.new(hostUID: myUID, hostName: myName)
        do {
            try FirestoreService.shared.createGameSession(newSession)
            session = newSession
            listenToSession(newSession.id)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func joinSession(_ s: GameSession) {
        session = s
        listenToSession(s.id)
        Task {
            var updated = s
            if !updated.players.contains(where: { $0.id == myUID }) {
                updated.players.append(SessionPlayer(
                    id: myUID, displayName: myName,
                    characterID: "", status: .joined, isReady: false,
                    turnIndex: updated.players.count
                ))
                updated.invitedUIDs.append(myUID)
                try? FirestoreService.shared.updateGameSession(updated)
            }
        }
    }

    func setReady(characterID: String) async {
        guard let s = session else { return }
        try? await FirestoreService.shared.updatePlayerReady(
            sessionID: s.id, uid: myUID, characterID: characterID, isReady: true
        )
    }

    func startSession() async {
        guard var s = session, isHost, allReady else { return }
        let playerCharID = s.players.first(where: { $0.id == myUID })?.characterID ?? ""
        let botIDs = s.botCharacterIDs
        let humanCharIDs = s.players.map(\.characterID).filter { !$0.isEmpty }
        s.gameState = GameState.newGame(
            playerCharacterID: playerCharID,
            botCharacterIDs: botIDs
        )
        s.status = .playing
        s.currentTurnUID = myUID
        s.currentTurnIndex = 0
        try? FirestoreService.shared.updateGameSession(s)
    }

    func invitePlayer(uid: String, name: String, via conversation: Conversation) async {
        guard let s = session else { return }
        var updated = s
        if !updated.invitedUIDs.contains(uid) { updated.invitedUIDs.append(uid) }
        try? FirestoreService.shared.updateGameSession(updated)

        let msg = ChatMessage(
            id: UUID().uuidString,
            conversationID: conversation.id,
            senderUID: myUID, senderName: myName,
            body: "\(myName) invited you to a D&D session 🎲",
            timestamp: Date(),
            inviteSessionID: s.id
        )
        try? await FirestoreService.shared.sendMessage(msg, in: conversation)
    }

    func submitAction(_ actionKey: String) async {
        guard let s = session, isMyTurn else { return }
        try? await FirestoreService.shared.submitAction(sessionID: s.id, actionJSON: actionKey)
    }

    func abandonSession() async {
        guard let s = session else { return }
        try? await FirestoreService.shared.abandonSession(id: s.id)
        session = nil
        sessionStreamTask?.cancel()
    }

    // MARK: — Streaming

    func listenToSession(_ id: String) {
        sessionStreamTask?.cancel()
        sessionStreamTask = Task {
            for await updated in FirestoreService.shared.gameSessionStream(sessionID: id) {
                session = updated
                if let gs = updated?.gameState {
                    localGameVM.gameState = gs
                }
            }
        }
    }

    func listenToMySessions() {
        mySessionsTask?.cancel()
        mySessionsTask = Task {
            for await sessions in FirestoreService.shared.myInvitedSessionsStream(uid: myUID) {
                mySessions = sessions
            }
        }
    }

    func stopListening() {
        sessionStreamTask?.cancel()
        mySessionsTask?.cancel()
    }
}
