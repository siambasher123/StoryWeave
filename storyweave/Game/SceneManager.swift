import Foundation

/// Manages scene transitions and game progression logic
/// Handles advancing between scenes based on player choices and tracking game state
struct SceneManager {
    /// Advances to the next scene based on the player's choice
    /// Uses the default CampaignStoryProvider for story content
    /// - Parameters:
    ///   - scene: Current game scene
    ///   - choice: Player's selected choice/action
    ///   - state: Current game state
    /// - Returns: Next GameScene or nil if choice is invalid
    static func advance(from scene: GameScene, choice: String, in state: GameState) -> GameScene? {
        advance(from: scene, choice: choice, in: state, provider: CampaignStoryProvider())
    }

    /// Advanced scene transition with custom story provider
    /// Checks for special transitions first, then follows normal scene progression
    /// - Parameters:
    ///   - scene: Current game scene
    ///   - choice: Player's selected choice/action
    ///   - state: Current game state
    ///   - provider: Custom story provider for scene resolution
    /// - Returns: Next GameScene or nil if choice is invalid
    static func advance(from scene: GameScene, choice: String, in state: GameState,
                        provider: any StoryProvider) -> GameScene? {
        // Check if there's a special transition (e.g., death, special events)
        if let special = provider.resolveSpecialTransition(sceneID: scene.id, state: state) {
            return special
        }
        // Find next scene from the current scene's available choices
        guard let nextID = scene.nextSceneIDs[choice] else { return nil }
        return provider.scene(id: nextID)
    }

    /// Retrieves the current Act based on game state
    /// - Parameter state: Current game state
    /// - Returns: Current Act or nil if not found
    static func currentAct(for state: GameState) -> Act? {
        StoryContent.acts.first(where: { $0.id == state.currentActIndex })
    }

    /// Checks if the game has ended
    /// Game ends when all characters are dead or the game over scene is reached
    /// - Parameter state: Current game state
    /// - Returns: true if game is over
    static func isGameOver(_ state: GameState) -> Bool {
        state.survivingCharacterIDs.isEmpty || state.currentSceneID == "game_over"
    }

    /// Checks if the game has been successfully completed
    /// - Parameter state: Current game state
    /// - Returns: true if the game complete scene has been reached
    static func isComplete(_ state: GameState) -> Bool {
        state.currentSceneID == "game_complete"
    }

    /// Determines which Act 5 ending the player gets based on their full decision record
    /// Evaluates key moral choices and character survival to determine narrative outcome
    /// - Parameters:
    ///   - decisions: Dictionary mapping scene IDs to player choices
    ///   - survivors: Array of surviving character IDs
    /// - Returns: The appropriate ending scene (true/dark/heroic/pyrrhic)
    static func resolveAct5Entry(decisions: [String: String], survivors: [String]) -> GameScene? {
        // Extract key decisions from the player's history
        let acceptedPact   = decisions["act4_scene7"] == "accept"
        let freedPrisoner  = decisions["act2_scene3"] == "free"
        let believedGuide  = decisions["act2_scene6"] == "believe"
        let savedCompanion = decisions["act3_scene7"] != nil   // any outcome = attempted to help
        let usedArtifact   = decisions["act4_scene9"] == "use_artifact"
        let manyAlive      = survivors.count >= 3

        // TRUE ENDING: Requires maximum positive choices + artifact use
        // Conditions: freed prisoner, believed guide, saved companion, refused pact, used artifact
        if freedPrisoner && believedGuide && savedCompanion && !acceptedPact && usedArtifact {
            return StoryContent.act5_true
        }
        
        // DARK ENDING: Accepting the pact overrides all other outcomes
        if acceptedPact {
            return StoryContent.act5_dark
        }
        
        // HEROIC ENDING: Refused the pact with sufficient party members alive
        if manyAlive && !acceptedPact {
            return StoryContent.act5_heroic
        }
        
        // PYRRHIC ENDING: Default outcome for heavy losses or incomplete objectives
        return StoryContent.act5_pyrrhic
    }
}
