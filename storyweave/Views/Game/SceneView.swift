import SwiftUI

struct SceneView: View {
    @ObservedObject var viewModel: GameViewModel
    let scene: GameScene

    private var atmosphere: AtmosphereType? {
        let seed = scene.narrationSeed.lowercased()
        if seed.contains("fire") || seed.contains("flame") || seed.contains("ember") { return .embers }
        if seed.contains("snow") || seed.contains("cold") || seed.contains("ice") { return .snow }
        if seed.contains("magic") || seed.contains("arcane") || seed.contains("crystal") { return .sparkles }
        if seed.contains("rain") || seed.contains("storm") { return .rain }
        return nil
    }

    private var isAct5: Bool {
        viewModel.gameState?.currentActIndex == 4
    }

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            if let atm = atmosphere {
                SceneAtmosphereView(type: atm)
            } else {
                AmbientParticleView()
            }

            sceneContent
                .id(scene.id)
                .transition(isAct5 ? .warpWipe : .sceneWipe)
        }
        .animation(.easeInOut(duration: 0.4), value: scene.id)
    }

    @ViewBuilder
    private var sceneContent: some View {
        switch scene.sceneType {
        case .exploration:
            ExplorationView(viewModel: viewModel, scene: scene)
        case .dialogue:
            DialogueView(viewModel: viewModel, scene: scene)
        case .combat:
            CombatView(viewModel: viewModel, scene: scene)
        case .skillCheck:
            SkillCheckView(viewModel: viewModel, scene: scene)
        }
    }
}
