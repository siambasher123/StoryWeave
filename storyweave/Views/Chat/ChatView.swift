import SwiftUI

// MARK: - ChatContentView (embeddable — no NavigationStack or title)

struct ChatContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Binding var selectedConversation: Conversation?
    @State private var segment = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $segment) {
                Text("Messages").tag(0)
                Text("People").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, swSpacing * 2)
            .padding(.vertical, swSpacing)

            Divider().background(Color.swSurfaceRaised)

            if segment == 0 {
                ConversationListView(viewModel: viewModel, selected: $selectedConversation)
            } else {
                UserDiscoveryView(viewModel: viewModel,
                                 onOpen: { conv in selectedConversation = conv; segment = 0 })
            }
        }
        .task { await viewModel.load() }
        .onDisappear { viewModel.stopListening() }
    }
}

// MARK: - Conversation List

struct ConversationListView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var selected: Conversation?

    var body: some View {
        if viewModel.conversations.isEmpty {
            SWEmptyStateView(
                icon: "bubble.left.and.bubble.right",
                title: "No messages yet",
                subtitle: "Connect with people to start chatting"
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.conversations) { conv in
                        ConversationRow(conversation: conv,
                                        myUID: viewModel.myUID ?? "")
                            .onTapGesture { selected = conv }
                        Divider().background(Color.swSurfaceRaised)
                            .padding(.leading, swSpacing * 9)
                    }
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let myUID: String

    private var unread: Int { conversation.unread(for: myUID) }

    var body: some View {
        HStack(spacing: swSpacing * 2) {
            SWAvatarView(name: conversation.peerName(for: myUID), size: 50, color: .swAccentPrimary)

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(conversation.peerName(for: myUID))
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                    Spacer()
                    Text(conversation.lastMessageTimestamp.formatted(.relative(presentation: .named)))
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }
                Text(conversation.lastMessageBody.isEmpty ? "Say hello!" : conversation.lastMessageBody)
                    .font(.swBody)
                    .foregroundStyle(unread > 0 ? Color.swTextPrimary : Color.swTextSecondary)
                    .fontWeight(unread > 0 ? .medium : .regular)
                    .lineLimit(1)
            }

            if unread > 0 {
                Text("\(min(unread, 99))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.swTextPrimary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.swAccentPrimary)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, swSpacing * 2)
        .padding(.vertical, swSpacing * 1.5)
        .contentShape(Rectangle())
    }
}

// MARK: - User Discovery

struct UserDiscoveryView: View {
    @ObservedObject var viewModel: ChatViewModel
    var onOpen: (Conversation) -> Void

    @State private var query = ""

    private var displayedUsers: [UserProfile] { viewModel.filteredUsers(query: query) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: swSpacing) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.swTextSecondary)
                TextField("Search people…", text: $query)
                    .foregroundStyle(Color.swTextPrimary)
                    .tint(Color.swAccentLight)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.swTextSecondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(swSpacing * 1.5)
            .background(Color.swSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, swSpacing * 2)
            .padding(.vertical, swSpacing)

            Divider().background(Color.swSurfaceRaised)

            if viewModel.allUsers.isEmpty {
                VStack(spacing: swSpacing * 2) {
                    ProgressView().tint(Color.swAccentPrimary)
                    Text("Loading people…")
                        .font(.swBody).foregroundStyle(Color.swTextSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if displayedUsers.isEmpty && !query.isEmpty {
                SWEmptyStateView(
                    icon: "person.slash",
                    title: "No results",
                    subtitle: "No one matches \"\(query)\""
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: swSpacing) {
                        if query.isEmpty && !viewModel.pendingIncoming.isEmpty {
                            sectionHeader("Connection Requests")
                                .padding(.bottom, -swSpacing * 0.5)
                            ForEach(viewModel.pendingIncoming) { conn in
                                let fromUID = conn.fromUID
                                if let user = viewModel.allUsers.first(where: { $0.id == fromUID }) {
                                    UserRow(user: user, state: .incomingPending,
                                            onConnect: {},
                                            onAccept: { Task { await viewModel.accept(conn) } },
                                            onDecline: { Task { await viewModel.decline(conn) } },
                                            onMessage: {})
                                } else {
                                    incomingRequestFallbackRow(conn)
                                }
                            }
                            sectionHeader("All People")
                                .padding(.top, swSpacing)
                                .padding(.bottom, -swSpacing * 0.5)
                        }

                        ForEach(displayedUsers) { user in
                            let state = viewModel.relationship(with: user.id)
                            let isInRequests = query.isEmpty &&
                                viewModel.pendingIncoming.contains(where: { $0.fromUID == user.id })
                            if !isInRequests {
                                UserRow(
                                    user: user, state: state,
                                    onConnect: { Task { await viewModel.sendRequest(to: user) } },
                                    onAccept: { Task {
                                        if let c = viewModel.pendingIncoming.first(where: { $0.fromUID == user.id }) {
                                            await viewModel.accept(c)
                                        }
                                    }},
                                    onDecline: { Task {
                                        if let c = viewModel.pendingIncoming.first(where: { $0.fromUID == user.id }) {
                                            await viewModel.decline(c)
                                        }
                                    }},
                                    onMessage: { Task {
                                        if let conv = await viewModel.openConversation(with: user.id) {
                                            onOpen(conv)
                                        }
                                    }}
                                )
                            }
                        }
                    }
                    .padding(swSpacing * 2)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.swCaption).fontWeight(.semibold)
            .foregroundStyle(Color.swTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func incomingRequestFallbackRow(_ conn: Connection) -> some View {
        HStack(spacing: swSpacing * 2) {
            SWAvatarView(name: conn.fromName, size: 46, color: .swWarning)
            VStack(alignment: .leading, spacing: 2) {
                Text(conn.fromName).font(.swHeadline).foregroundStyle(Color.swTextPrimary)
                Text("wants to connect").font(.swCaption).foregroundStyle(Color.swTextSecondary)
            }
            Spacer()
            connectionActionButtons(
                onAccept: { Task { await viewModel.accept(conn) } },
                onDecline: { Task { await viewModel.decline(conn) } }
            )
        }
        .padding(swSpacing * 2)
        .background(Color.swSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    private func connectionActionButtons(onAccept: @escaping () -> Void, onDecline: @escaping () -> Void) -> some View {
        HStack(spacing: swSpacing) {
            Button(action: onDecline) {
                Image(systemName: "xmark").font(.callout.weight(.semibold))
                    .foregroundStyle(Color.swDanger)
                    .frame(width: 34, height: 34)
                    .background(Color.swDanger.opacity(0.12)).clipShape(Circle())
            }
            .accessibilityLabel("Decline request")
            Button(action: onAccept) {
                Image(systemName: "checkmark").font(.callout.weight(.semibold))
                    .foregroundStyle(Color.swAccentHighlight)
                    .frame(width: 34, height: 34)
                    .background(Color.swAccentHighlight.opacity(0.12)).clipShape(Circle())
            }
            .accessibilityLabel("Accept request")
        }
    }
}

// MARK: - User Row

struct UserRow: View {
    let user: UserProfile
    let state: ChatViewModel.RelationshipState
    var onConnect: () -> Void
    var onAccept:  () -> Void
    var onDecline: () -> Void
    var onMessage: () -> Void

    var body: some View {
        HStack(spacing: swSpacing * 2) {
            SWAvatarView(name: user.displayName, size: 46, color: avatarColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName).font(.swHeadline).foregroundStyle(Color.swTextPrimary)
                Text(stateLabel).font(.swCaption).foregroundStyle(Color.swTextSecondary)
            }

            Spacer()

            switch state {
            case .none:
                PillButton("Connect", bg: Color.swAccentPrimary, fg: Color.swTextPrimary, action: onConnect)
                    .accessibilityLabel("Connect with \(user.displayName)")
            case .outgoingPending:
                PillButton("Pending", bg: Color.swSurfaceRaised, fg: Color.swTextSecondary, action: {})
                    .disabled(true)
                    .accessibilityLabel("Connection request pending")
            case .incomingPending:
                HStack(spacing: swSpacing) {
                    Button(action: onDecline) {
                        Image(systemName: "xmark").font(.callout.weight(.semibold))
                            .foregroundStyle(Color.swDanger)
                            .frame(width: 34, height: 34)
                            .background(Color.swDanger.opacity(0.12)).clipShape(Circle())
                    }
                    .accessibilityLabel("Decline \(user.displayName)'s request")
                    Button(action: onAccept) {
                        Image(systemName: "checkmark").font(.callout.weight(.semibold))
                            .foregroundStyle(Color.swAccentHighlight)
                            .frame(width: 34, height: 34)
                            .background(Color.swAccentHighlight.opacity(0.12)).clipShape(Circle())
                    }
                    .accessibilityLabel("Accept \(user.displayName)'s request")
                }
            case .connected:
                PillButton("Message", bg: Color.swAccentPrimary.opacity(0.15),
                           fg: Color.swAccentPrimary, action: onMessage)
                    .accessibilityLabel("Message \(user.displayName)")
            }
        }
        .padding(swSpacing * 2)
        .background(Color.swSurface, in: RoundedRectangle(cornerRadius: 14))
    }

    private var avatarColor: Color {
        switch state {
        case .none: return Color.swAccentPrimary
        case .outgoingPending: return Color.swTextSecondary
        case .incomingPending: return Color.swWarning
        case .connected: return Color.swAccentHighlight
        }
    }

    private var stateLabel: String {
        switch state {
        case .none: return "Tap Connect to add"
        case .outgoingPending: return "Request sent"
        case .incomingPending: return "Wants to connect"
        case .connected: return "Connected"
        }
    }
}

private struct PillButton: View {
    let title: String
    let bg: Color
    let fg: Color
    let action: () -> Void

    init(_ title: String, bg: Color, fg: Color, action: @escaping () -> Void) {
        self.title = title; self.bg = bg; self.fg = fg; self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title).font(.swCaption).fontWeight(.semibold)
                .foregroundStyle(fg)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(bg).clipShape(Capsule())
        }
    }
}
