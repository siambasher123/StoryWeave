import Foundation

/// Protocol defining the contract for story content providers
/// Implementations handle scene retrieval and special transition logic
/// This allows different story sources (campaign, user-created) to be used interchangeably
protocol StoryProvider: Sendable {
    /// The scene ID where the story begins
    var startSceneID: String { get }
    
    /// Retrieves a scene by its unique identifier
    /// - Parameter id: Scene identifier to look up
    /// - Returns: GameScene if found, nil otherwise
    func scene(id: String) -> GameScene?
    
    /// Handles special scene transitions based on game state
    /// Used for dynamic branching like multi-ending systems (e.g., Act 5 endings)
    /// - Parameters:
    ///   - sceneID: Current scene identifier
    ///   - state: Current game state (decisions, survivors, etc.)
    /// - Returns: Override scene if a special transition applies, nil for normal flow
    func resolveSpecialTransition(sceneID: String, state: GameState) -> GameScene?
}

/// The main campaign story provider
/// Serves all built-in campaign content with special ending resolution logic
struct CampaignStoryProvider: StoryProvider {
    /// Campaign always starts at Act 1, Scene 1
    let startSceneID = "act1_scene1"

    /// Retrieves scenes from the built-in StoryContent campaign
    /// - Parameter id: Scene identifier
    /// - Returns: Scene from campaign or nil if not found
    func scene(id: String) -> GameScene? {
        StoryContent.scene(id: id)
    }

    /// Resolves the Act 5 ending based on the player's full decision history
    /// When the player reaches "act5_entry", this method determines which ending they get
    /// (true/dark/heroic/pyrrhic) based on their choices throughout the game
    /// - Parameters:
    ///   - sceneID: Current scene ID
    ///   - state: Game state containing decision history and survivors
    /// - Returns: The appropriate ending scene, or nil for non-Act5 transitions
    func resolveSpecialTransition(sceneID: String, state: GameState) -> GameScene? {
        guard sceneID == "act5_entry" else { return nil }
        return SceneManager.resolveAct5Entry(decisions: state.decisionHistory,
                                             survivors: state.survivingCharacterIDs)
    }
}

/// Provider for user-created custom stories
/// Adapts UserStory data structures into the standard GameScene format
/// Allows players to design and play their own branching narratives
struct UserStoryProvider: StoryProvider {
    let story: UserStory

    /// Gets the starting scene from the user story
    var startSceneID: String { story.startSceneID }

    /// Retrieves a scene from the user story and converts it to GameScene format
    /// - Parameter id: Scene identifier within the user story
    /// - Returns: Converted GameScene or nil if not found
    func scene(id: String) -> GameScene? {
        story.scenes.first(where: { $0.id == id }).map(toGameScene)
    }

    /// User stories don't support special transitions
    /// All scenes follow normal branching paths
    func resolveSpecialTransition(sceneID: String, state: GameState) -> GameScene? { nil }

    /// Converts a UserStoryScene into a standard GameScene
    /// Handles transformation of optional combat and skill check configs
    /// Maps user-provided scene data into the engine's data structures
    /// - Parameter s: UserStoryScene to convert
    /// - Returns: Fully formed GameScene ready for gameplay
    private func toGameScene(_ s: UserStoryScene) -> GameScene {
        // Build combat config if the scene has enemies
        let combat: CombatConfig? = s.enemies.flatMap { templates -> CombatConfig? in
            guard !templates.isEmpty else { return nil }
            let enemies = templates.map {
                Enemy(id: $0.id, name: $0.name, emoji: $0.emoji,
                      hp: $0.hp, maxHP: $0.hp, atk: $0.atk, def: $0.def, dex: $0.dex)
            }
            return CombatConfig(enemies: enemies, fleeSceneID: nil)
        }
        
        // Build skill check config if the scene requires an ability check
        let skillCheck: SkillCheckConfig? = s.skillCheckStat.map { stat in
            SkillCheckConfig(
                stat: stat,
                difficultyDC: s.skillCheckDC ?? 12,
                successSceneID: s.skillCheckSuccessSceneID ?? s.id,
                failureSceneID: s.skillCheckFailureSceneID ?? s.id
            )
        }
        
        // Convert choice labels to standardized SceneChoice objects with consistent IDs
        let sceneChoices = s.choices.enumerated().map { idx, label in
            SceneChoice(id: "\(s.id)_c\(idx)", key: "\(idx)", label: label)
        }
        
        // Assemble final GameScene with converted data
        return GameScene(
            id: s.id, actIndex: 0, sceneType: s.sceneType,
            narrationSeed: s.narrationText,
            choices: sceneChoices, nextSceneIDs: s.nextSceneIDs,
            combat: combat, skillCheck: skillCheck, npcName: s.npcName
        )
    }
}
