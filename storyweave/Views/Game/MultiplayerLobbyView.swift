import SwiftUI

struct MultiplayerLobbyView: View {
    @ObservedObject var vm: MultiplayerViewModel
    @StateObject private var browserVM = CharacterBrowserViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCharID: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()

                if vm.session == nil {
                    createOrJoinView
                } else {
                    lobbyView
                }
            }
            .navigationTitle("Multiplayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
        .task { await browserVM.load() }
        .onDisappear { vm.stopListening() }
    }

    // MARK: — Create / Join

    private var createOrJoinView: some View {
        VStack(spacing: swSpacing * 3) {
            Image(systemName: "dice.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.swAccentPrimary)

            Text("Play D&D with Friends")
                .font(.swTitle).foregroundStyle(Color.swTextPrimary).multilineTextAlignment(.center)

            Text("Create a session and invite connected friends, or join a pending session from your Chat tab.")
                .font(.swBody).foregroundStyle(Color.swTextSecondary).multilineTextAlignment(.center)
                .padding(.horizontal, swSpacing * 3)

            SWButton(title: "Create Session", style: .primary) {
                Task { await vm.createSession() }
            }
            .frame(maxWidth: 260)

            if vm.isLoading { ProgressView().tint(Color.swAccentPrimary) }
            if let err = vm.error {
                Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
            }
        }
        .padding(swSpacing * 3)
    }

    // MARK: — Lobby

    private var lobbyView: some View {
        ScrollView {
            VStack(spacing: swSpacing * 2) {
                sessionInfoCard
                playerListSection
                characterPickerSection
                partyRulesNote
                if vm.isHost { startButton }
            }
            .padding(swSpacing * 2)
        }
    }

    private var sessionInfoCard: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                HStack {
                    SWPillBadge(text: "LOBBY", color: .swAccentMuted)
                    Spacer()
                    Text("Session ID")
                        .font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    Text(String(vm.session?.id.prefix(8) ?? ""))
                        .font(.swCaption).foregroundStyle(Color.swAccentLight)
                }
                Text("Invite friends via Chat — send them this session ID or use the invite button in a conversation.")
                    .font(.swCaption).foregroundStyle(Color.swTextSecondary)
            }
        }
    }

    private var playerListSection: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            Text("Players").font(.swHeadline).foregroundStyle(Color.swTextPrimary)
            ForEach(vm.session?.players ?? []) { player in
                HStack {
                    Circle()
                        .fill(player.isReady ? Color.swSuccess : Color.swSurface)
                        .frame(width: 10, height: 10)
                    Text(player.displayName)
                        .font(.swBody).foregroundStyle(Color.swTextPrimary)
                    if player.id == vm.session?.hostUID {
                        SWPillBadge(text: "HOST", color: .swAccentPrimary)
                    }
                    Spacer()
                    Text(player.isReady ? "Ready" : "Not ready")
                        .font(.swCaption)
                        .foregroundStyle(player.isReady ? Color.swSuccess : Color.swTextSecondary)
                }
                .padding(swSpacing)
                .background(Color.swSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var characterPickerSection: some View {
        VStack(alignment: .leading, spacing: swSpacing) {
            Text("Your Character").font(.swHeadline).foregroundStyle(Color.swTextPrimary)
            if browserVM.isLoading {
                ProgressView().tint(Color.swAccentPrimary)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: swSpacing) {
                    ForEach(browserVM.characters) { char in
                        Button {
                            selectedCharID = char.id
                            Task { await vm.setReady(characterID: char.id) }
                        } label: {
                            VStack(spacing: 4) {
                                Text(archetypeIcon(char.archetype)).font(.title2)
                                Text(char.name).font(.swCaption).foregroundStyle(Color.swTextPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(swSpacing)
                            .background(selectedCharID == char.id ? Color.swAccentPrimary.opacity(0.25) : Color.swSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedCharID == char.id ? Color.swAccentPrimary : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var partyRulesNote: some View {
        Text("At least 2 human players required for a 0-bot game. You can add bots if playing solo or with 1 friend.")
            .font(.swCaption).foregroundStyle(Color.swTextSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, swSpacing)
    }

    private var startButton: some View {
        VStack(spacing: swSpacing) {
            SWButton(
                title: vm.allReady ? "Start Adventure" : "Waiting for players...",
                style: vm.allReady ? .primary : .secondary
            ) {
                Task { await vm.startSession() }
            }
            .disabled(!vm.allReady)

            SWButton(title: "Abandon Session", style: .danger) {
                Task { await vm.abandonSession(); dismiss() }
            }
        }
    }

    private func archetypeIcon(_ arch: Archetype) -> String {
        switch arch {
        case .warrior: "⚔️"; case .mage: "🔮"; case .rogue: "🗡"
        case .cleric: "✨"; case .ranger: "🏹"; case .tank: "🛡"
        }
    }
}
