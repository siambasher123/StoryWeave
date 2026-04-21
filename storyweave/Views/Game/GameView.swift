import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @StateObject private var multiplayerVM = MultiplayerViewModel()
    @State private var landingSegment = 0
    @State private var showMultiplayer = false

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            if let scene = viewModel.currentScene, !viewModel.isGameOver, !viewModel.isGameComplete {
                SceneView(viewModel: viewModel, scene: scene)
            } else if viewModel.gameState == nil {
                landingView
            } else if !viewModel.isGameOver && !viewModel.isGameComplete {
                ProgressView().tint(Color.swAccentPrimary)
            }

            if viewModel.isGameOver {
                GameOverView(viewModel: viewModel)
            }

            if viewModel.isGameComplete {
                GameCompleteView(viewModel: viewModel)
            }

            if viewModel.showLevelUp {
                LevelUpEffectView(level: viewModel.gameState?.playerLevel ?? 1)
                    .transition(.opacity)
            }
        }
        .task { await viewModel.loadGame() }
        .sheet(isPresented: $showMultiplayer) {
            MultiplayerLobbyView(vm: multiplayerVM)
        }
    }

    private var landingView: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                Picker("", selection: $landingSegment) {
                    Text("Campaign").tag(0)
                    Text("Community").tag(1)
                    Text("Sessions").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, swSpacing * 2)
                .padding(.vertical, swSpacing)
                .background(Color.swBackground)

                if landingSegment == 0 {
                    PartySelectionView(viewModel: viewModel)
                } else if landingSegment == 1 {
                    CommunityStoriesView(gameVM: viewModel)
                } else {
                    MySessionsView()
                }
            }

            if landingSegment == 0 {
                Button {
                    showMultiplayer = true
                } label: {
                    HStack(spacing: swSpacing) {
                        Image(systemName: "dice.fill")
                        Text("Multiplayer")
                            .font(.swCaption).fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.swTextPrimary)
                    .padding(.horizontal, swSpacing * 2)
                    .padding(.vertical, swSpacing)
                    .background(Color.swAccentPrimary)
                    .clipShape(Capsule())
                    .shadow(color: Color.swAccentPrimary.opacity(0.4), radius: 8)
                }
                .accessibilityLabel("Start multiplayer game")
                .padding(.trailing, swSpacing * 2)
                .padding(.bottom, swSpacing * 2)
            }
        }
    }
}

struct GameOverView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            Color.swBackground.opacity(0.96).ignoresSafeArea()

            VStack(spacing: swSpacing * 3) {
                Text("Game Over")
                    .font(.swDisplay)
                    .foregroundStyle(Color.swDanger)
                    .accessibilityLabel("Game over")

                Text("Your party has fallen...")
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)

                SWButton(title: "Restart Adventure", style: .danger) {
                    Task { await viewModel.restart() }
                }
                .frame(maxWidth: 260)
                .accessibilityLabel("Restart adventure from beginning")

                SWButton(title: "Return to Menu", style: .secondary) {
                    viewModel.gameState = nil
                    viewModel.isGameOver = false
                }
                .frame(maxWidth: 260)
                .accessibilityLabel("Return to party selection")
            }
            .padding(swSpacing * 4)
        }
    }
}

struct GameCompleteView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()
            CriticalHitParticleView()

            VStack(spacing: swSpacing * 3) {
                Text("The End")
                    .font(.swDisplay)
                    .foregroundStyle(Color.swAccentPrimary)
                    .accessibilityLabel("Game complete")

                Text("Your legend echoes through eternity.")
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)
                    .multilineTextAlignment(.center)

                XPCounterView(from: (viewModel.gameState?.playerXP ?? 0) - 500,
                              to: viewModel.gameState?.playerXP ?? 0)

                Spacer().frame(height: swSpacing)

                SWButton(title: "Play Again", style: .primary) {
                    Task { await viewModel.restart() }
                }
                .frame(maxWidth: 260)
                .accessibilityLabel("Play again with same party")

                SWButton(title: "New Adventure", style: .secondary) {
                    viewModel.isGameComplete = false
                    viewModel.gameState = nil
                }
                .frame(maxWidth: 260)
                .accessibilityLabel("Return to party selection for a fresh start")
            }
            .padding(swSpacing * 4)
        }
    }
}
