import Foundation

struct SceneManager {
    static func advance(from scene: GameScene, choice: String, in state: GameState) -> GameScene? {
        advance(from: scene, choice: choice, in: state, provider: CampaignStoryProvider())
    }

    static func advance(from scene: GameScene, choice: String, in state: GameState,
                        provider: any StoryProvider) -> GameScene? {
        if let special = provider.resolveSpecialTransition(sceneID: scene.id, state: state) {
            return special
        }
        guard let nextID = scene.nextSceneIDs[choice] else { return nil }
        return provider.scene(id: nextID)
    }

    static func currentAct(for state: GameState) -> Act? {
        StoryContent.acts.first(where: { $0.id == state.currentActIndex })
    }

    static func isGameOver(_ state: GameState) -> Bool {
        state.survivingCharacterIDs.isEmpty || state.currentSceneID == "game_over"
    }

    static func isComplete(_ state: GameState) -> Bool {
        state.currentSceneID == "game_complete"
    }

    // Determines which Act 5 ending the player gets based on their full decision record.
    static func resolveAct5Entry(decisions: [String: String], survivors: [String]) -> GameScene? {
        let acceptedPact   = decisions["act4_scene7"] == "accept"
        let freedPrisoner  = decisions["act2_scene3"] == "free"
        let believedGuide  = decisions["act2_scene6"] == "believe"
        let savedCompanion = decisions["act3_scene7"] != nil   // any outcome = attempted to help
        let usedArtifact   = decisions["act4_scene9"] == "use_artifact"
        let manyAlive      = survivors.count >= 3

        // True ending: all positive choices + artifact
        if freedPrisoner && believedGuide && savedCompanion && !acceptedPact && usedArtifact {
            return StoryContent.act5_true
        }
        // Dark ending: accepted the compact
        if acceptedPact {
            return StoryContent.act5_dark
        }
        // Heroic: refused pact, enough survivors
        if manyAlive && !acceptedPact {
            return StoryContent.act5_heroic
        }
        // Pyrrhic: heavy losses or self-sacrifice
        return StoryContent.act5_pyrrhic
    }
}
