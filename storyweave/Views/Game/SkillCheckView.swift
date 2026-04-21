import SwiftUI

struct SkillCheckView: View {
    @ObservedObject var viewModel: GameViewModel
    let scene: GameScene

    @State private var rollResult: Int?
    @State private var showDiceRoll = false
    @State private var outcome: CombatOutcome?
    @State private var resolvedNextSceneID: String?

    private var config: SkillCheckConfig? { scene.skillCheck }

    var body: some View {
        ScrollView {
            VStack(spacing: swSpacing * 3) {
                NarrationPanel(narration: viewModel.narration, isLoading: viewModel.isLoadingNarration)

                if let config {
                    statBadge(for: config.stat, dc: config.difficultyDC)
                    HStack(spacing: swSpacing * 2) {
                        Spacer()
                        MagicOrbView().frame(width: 70, height: 70)
                        Spacer()
                    }
                }

                if let result = rollResult, showDiceRoll {
                    EnhancedDiceRollView(result: result) {
                        resolveOutcome(roll: result)
                    }
                } else if let outcome {
                    outcomePanel(outcome: outcome)
                } else {
                    SWButton(title: "Roll d20", style: .primary) {
                        let roll = CombatEngine.rollD20()
                        rollResult = roll
                        showDiceRoll = true
                    }
                    .accessibilityLabel("Roll twenty-sided die")
                }

                PartyStatusBar(party: viewModel.party)
            }
            .padding(swSpacing * 2)
        }
    }

    // MARK: — Helpers

    private func statBadge(for stat: StatType, dc: Int) -> some View {
        HStack(spacing: swSpacing) {
            SWPillBadge(text: stat.rawValue.uppercased(), color: .swAccentMuted)
            SWPillBadge(text: "DC \(dc)", color: .swAccentDeep)
        }
        .accessibilityLabel("Skill check: \(stat.rawValue), difficulty \(dc)")
    }

    private func outcomePanel(outcome: CombatOutcome) -> some View {
        VStack(spacing: swSpacing * 2) {
            Text(outcomeText(for: outcome))
                .font(.swTitle)
                .foregroundStyle(outcomeColor(for: outcome))
                .accessibilityLabel("Outcome: \(outcomeText(for: outcome))")

            if let nextID = resolvedNextSceneID {
                SWButton(title: "Continue", style: .primary) {
                    Task { await viewModel.advanceToScene(nextID) }
                }
                .accessibilityLabel("Continue to next scene")
            } else {
                ForEach(scene.choices) { choice in
                    SWButton(title: choice.label, style: .primary) {
                        Task { await viewModel.makeChoice(choice) }
                    }
                    .accessibilityLabel(choice.label)
                }
            }
        }
    }

    private func resolveOutcome(roll: Int) {
        guard let config, let player = viewModel.party.first(where: { $0.id == viewModel.gameState?.playerCharacterID }) else {
            showDiceRoll = false
            return
        }
        let (resolvedOutcome, _) = CombatEngine.resolveSkillCheck(character: player, stat: config.stat, difficulty: config.difficultyDC)
        outcome = resolvedOutcome
        resolvedNextSceneID = (resolvedOutcome == .fail || resolvedOutcome == .criticalFail)
            ? config.failureSceneID
            : config.successSceneID
        showDiceRoll = false

        switch resolvedOutcome {
        case .criticalFail:    HapticEngine.play(.error)
        case .fail:            HapticEngine.play(.warning)
        case .partialSuccess:  HapticEngine.play(.impact(.medium))
        case .success:         HapticEngine.play(.success)
        case .criticalSuccess: HapticEngine.play(.impact(.heavy))
        }

        Task { await viewModel.trackSkillCheckPublic(passed: resolvedOutcome != .fail && resolvedOutcome != .criticalFail) }
    }

    private func outcomeText(for outcome: CombatOutcome) -> String {
        switch outcome {
        case .criticalFail:    return "Critical Failure!"
        case .fail:            return "Failure"
        case .partialSuccess:  return "Partial Success"
        case .success:         return "Success!"
        case .criticalSuccess: return "Critical Success!"
        }
    }

    private func outcomeColor(for outcome: CombatOutcome) -> Color {
        switch outcome {
        case .criticalFail:    return .swDanger
        case .fail:            return .swAccentSecondary
        case .partialSuccess:  return .swWarning
        case .success:         return .swSuccess
        case .criticalSuccess: return .swAccentLight
        }
    }
}
