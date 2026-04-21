import SwiftUI

struct ExplorationView: View {
    @ObservedObject var viewModel: GameViewModel
    let scene: GameScene

    var body: some View {
        ZStack {
            ExplorationParallaxView {
                Color.swAccentDeep.opacity(0.15)
                    .ignoresSafeArea()
            }
            mainContent

            if let item = viewModel.lastPickedUpItem {
                Color.swBackground.opacity(0.75).ignoresSafeArea()
                    .transition(.opacity)
                ItemRevealCardView(item: item) {
                    viewModel.lastPickedUpItem = nil
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.lastPickedUpItem?.id)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: swSpacing * 3) {
                if let state = viewModel.gameState,
                   let act = StoryContent.acts.first(where: { $0.id == state.currentActIndex }) {
                    Text(act.title.uppercased())
                        .font(.swCaption)
                        .foregroundStyle(Color.swAccentPrimary)
                        .tracking(2)
                }

                NarrationPanel(
                    narration: viewModel.narration,
                    isLoading: viewModel.isLoadingNarration
                )

                VStack(spacing: swSpacing) {
                    ForEach(scene.choices) { choice in
                        SWButton(title: choice.label, style: .secondary) {
                            Task { await viewModel.makeChoice(choice) }
                        }
                        .accessibilityLabel(choice.label)
                    }
                }

                PartyStatusBar(party: viewModel.party)
            }
            .padding(swSpacing * 2)
        }
    }
}

struct NarrationPanel: View {
    let narration: String
    let isLoading: Bool

    var body: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                if isLoading && narration.isEmpty {
                    HStack {
                        ProgressView().tint(Color.swAccentPrimary)
                        Text("The story unfolds...")
                            .font(.swBody)
                            .foregroundStyle(Color.swTextSecondary)
                    }
                } else {
                    Text(narration.isEmpty ? "Darkness stirs..." : narration)
                        .font(.swBody)
                        .foregroundStyle(Color.swTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

struct PartyStatusBar: View {
    let party: [Character]

    var body: some View {
        HStack(spacing: swSpacing) {
            ForEach(party) { member in
                VStack(spacing: 4) {
                    Text(member.name.prefix(6))
                        .font(.swCaption)
                        .foregroundStyle(member.hp > 0 ? Color.swTextPrimary : Color.swTextSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.swSurface)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(hpColor(for: member))
                                .frame(width: geo.size.width * CGFloat(member.hp) / CGFloat(max(member.maxHP, 1)))
                        }
                    }
                    .frame(height: 6)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(swSpacing)
        .background(Color.swSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func hpColor(for char: Character) -> Color {
        let pct = Double(char.hp) / Double(max(char.maxHP, 1))
        if pct > 0.5 { return .swSuccess }
        if pct > 0.25 { return .swWarning }
        return .swDanger
    }
}
