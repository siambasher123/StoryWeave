import SwiftUI

struct ConversationView: View {
    let conversation: Conversation
    @StateObject private var viewModel = ConversationViewModel()
    @StateObject private var multiplayerVM = MultiplayerViewModel()
    @FocusState private var inputFocused: Bool
    @State private var joinSessionID: String?
    @State private var showMultiplayerLobby = false

    private var myUID: String { viewModel.myUID ?? "" }
    private var peerName: String { conversation.peerName(for: myUID) }

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                messagesList
                inputBar
            }
        }
        .navigationTitle(peerName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.startListening(conversationID: conversation.id)
            await viewModel.markRead(conversationID: conversation.id)
        }
        .onDisappear { viewModel.stopListening() }
        .sheet(isPresented: $showMultiplayerLobby) { MultiplayerLobbyView(vm: multiplayerVM) }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: swSpacing) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg, isFromMe: msg.senderUID == myUID) { sid in
                            joinSessionID = sid
                            showMultiplayerLobby = true
                        }
                        .id(msg.id)
                    }
                }
                .padding(.horizontal, swSpacing * 2)
                .padding(.vertical, swSpacing * 2)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let last = viewModel.messages.last {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let last = viewModel.messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: swSpacing) {
            TextField("Message…", text: $viewModel.inputText, axis: .vertical)
                .foregroundStyle(Color.swTextPrimary)
                .tint(Color.swAccentLight)
                .font(.swBody)
                .lineLimit(1...5)
                .padding(.horizontal, swSpacing * 2)
                .padding(.vertical, swSpacing * 1.5)
                .background(Color.swSurface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .focused($inputFocused)

            Button {
                Task { await viewModel.send(in: conversation) }
                HapticEngine.play(.impact(.medium))
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                     ? Color.swTextSecondary : Color.swAccentPrimary)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                      || viewModel.isSending)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, swSpacing * 2)
        .padding(.vertical, swSpacing)
        .background(Color.swSurfaceRaised)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let isFromMe: Bool
    var onJoinSession: ((String) -> Void)?

    var body: some View {
        HStack(alignment: .bottom, spacing: swSpacing) {
            if isFromMe { Spacer(minLength: 60) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 3) {
                if let sessionID = message.inviteSessionID, !isFromMe {
                    SessionInviteRow(message: message) { _ in
                        onJoinSession?(sessionID)
                    }
                } else {
                    Text(message.body)
                        .font(.swBody)
                        .foregroundStyle(isFromMe ? .white : Color.swTextPrimary)
                        .padding(.horizontal, swSpacing * 2)
                        .padding(.vertical, swSpacing * 1.5)
                        .background(isFromMe ? Color.swAccentPrimary : Color.swSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 10))
                    .foregroundStyle(Color.swTextSecondary)
                    .padding(.horizontal, swSpacing)
            }

            if !isFromMe { Spacer(minLength: 60) }
        }
    }
}
