import SwiftUI
import FirebaseAuth

struct MySessionsView: View {
    @StateObject private var vm = MultiplayerViewModel()
    @State private var showLobby = false

    var body: some View {
        ZStack {
            LinearGradient.swGradientBackground.ignoresSafeArea()

            if vm.mySessions.isEmpty {
                VStack(spacing: swSpacing * 3) {
                    SWEmptyStateView(
                        icon: "dice",
                        title: "No active sessions",
                        subtitle: "Start a new multiplayer D&D session and invite friends."
                    )
                    SWButton(title: "Create Session", style: .primary) {
                        showLobby = true
                    }
                    .frame(width: 200)
                    .padding(.horizontal, swSpacing * 4)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: swSpacing) {
                        ForEach(vm.mySessions) { session in
                            SessionRowView(
                                session: session,
                                myUID: vm.myUID,
                                onJoin: {
                                    vm.joinSession(session)
                                    showLobby = true
                                },
                                onAbandon: {
                                    Task { try? await FirestoreService.shared.abandonSession(id: session.id) }
                                }
                            )
                        }
                    }
                    .padding(swSpacing * 2)
                }
            }
        }
        .onAppear { vm.listenToMySessions() }
        .onDisappear { vm.stopListening() }
        .sheet(isPresented: $showLobby) { MultiplayerLobbyView(vm: vm) }
    }
}

private struct SessionRowView: View {
    let session: GameSession
    let myUID: String
    let onJoin: () -> Void
    let onAbandon: () -> Void

    private var isHost: Bool { session.hostUID == myUID }

    var body: some View {
        SWCard {
            VStack(spacing: swSpacing) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            SWPillBadge(
                                text: session.status.rawValue.uppercased(),
                                color: session.status == .playing ? .swSuccess : .swAccentMuted
                            )
                            Text("\(session.players.count) players")
                                .font(.swCaption).foregroundStyle(Color.swTextSecondary)
                        }
                        Text("Host: \(session.players.first(where: { $0.id == session.hostUID })?.displayName ?? "Unknown")")
                            .font(.swBody).foregroundStyle(Color.swTextPrimary)
                    }
                    Spacer()
                    SWButton(title: "Join", style: .primary) { onJoin() }
                        .frame(width: 80)
                }

                HStack {
                    Spacer()
                    Button(action: onAbandon) {
                        Text(isHost ? "Abandon" : "Leave")
                            .font(.swCaption)
                            .foregroundStyle(Color.swDanger)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isHost ? "Abandon session" : "Leave session")
                }
            }
        }
    }
}
