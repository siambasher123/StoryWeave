import SwiftUI
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isSending = false

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private var listenTask: Task<Void, Never>?

    var myUID: String? { auth.currentUserID }

    func startListening(conversationID: String) {
        listenTask?.cancel()
        listenTask = Task {
            for await msgs in firestore.messagesStream(conversationID: conversationID) {
                guard !Task.isCancelled else { break }
                messages = msgs
            }
        }
    }

    func stopListening() { listenTask?.cancel() }

    func markRead(conversationID: String) async {
        guard let uid = myUID else { return }
        try? await firestore.markConversationRead(conversationID: conversationID, uid: uid)
    }

    func send(in conversation: Conversation) async {
        let body = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, let uid = myUID else { return }
        inputText = ""
        isSending = true
        defer { isSending = false }
        let name = conversation.participantNames[uid] ?? "You"
        let msg = ChatMessage(id: UUID().uuidString, conversationID: conversation.id,
                              senderUID: uid, senderName: name, body: body, timestamp: Date())
        try? await firestore.sendMessage(msg, in: conversation)
    }
}
