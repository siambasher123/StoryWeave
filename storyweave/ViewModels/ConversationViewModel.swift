import SwiftUI
import Combine

@MainActor
final class ConversationViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isSending = false
    @Published var editingMessage: ChatMessage? = nil

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
        guard !body.isEmpty else { return }

        if var editing = editingMessage {
            editing.body = body
            messages = messages.map { $0.id == editing.id ? editing : $0 }
            try? firestore.updateMessage(editing)
            inputText = ""
            editingMessage = nil
            return
        }

        guard let uid = myUID else { return }
        inputText = ""
        isSending = true
        defer { isSending = false }
        let name = conversation.participantNames[uid] ?? "You"
        let msg = ChatMessage(id: UUID().uuidString, conversationID: conversation.id,
                              senderUID: uid, senderName: name, body: body, timestamp: Date())
        try? await firestore.sendMessage(msg, in: conversation)
    }

    func startEdit(_ message: ChatMessage) {
        editingMessage = message
        inputText = message.body
    }

    func cancelEdit() {
        editingMessage = nil
        inputText = ""
    }

    func deleteMessage(_ message: ChatMessage) {
        messages.removeAll { $0.id == message.id }
        Task { try? await firestore.deleteMessage(messageID: message.id, conversationID: message.conversationID) }
    }
}
