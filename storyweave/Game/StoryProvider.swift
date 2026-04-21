import Foundation

protocol StoryProvider: Sendable {
    var startSceneID: String { get }
    func scene(id: String) -> GameScene?
    func resolveSpecialTransition(sceneID: String, state: GameState) -> GameScene?
}

struct CampaignStoryProvider: StoryProvider {
    let startSceneID = "act1_scene1"

    func scene(id: String) -> GameScene? {
        StoryContent.scene(id: id)
    }

    func resolveSpecialTransition(sceneID: String, state: GameState) -> GameScene? {
        guard sceneID == "act5_entry" else { return nil }
        return SceneManager.resolveAct5Entry(decisions: state.decisionHistory,
                                             survivors: state.survivingCharacterIDs)
    }
}

struct UserStoryProvider: StoryProvider {
    let story: UserStory

    var startSceneID: String { story.startSceneID }

    func scene(id: String) -> GameScene? {
        story.scenes.first(where: { $0.id == id }).map(toGameScene)
    }

    func resolveSpecialTransition(sceneID: String, state: GameState) -> GameScene? { nil }

    private func toGameScene(_ s: UserStoryScene) -> GameScene {
        let combat: CombatConfig? = s.enemies.flatMap { templates -> CombatConfig? in
            guard !templates.isEmpty else { return nil }
            let enemies = templates.map {
                Enemy(id: $0.id, name: $0.name, emoji: $0.emoji,
                      hp: $0.hp, maxHP: $0.hp, atk: $0.atk, def: $0.def, dex: $0.dex)
            }
            return CombatConfig(enemies: enemies, fleeSceneID: nil)
        }
        let skillCheck: SkillCheckConfig? = s.skillCheckStat.map { stat in
            SkillCheckConfig(
                stat: stat,
                difficultyDC: s.skillCheckDC ?? 12,
                successSceneID: s.skillCheckSuccessSceneID ?? s.id,
                failureSceneID: s.skillCheckFailureSceneID ?? s.id
            )
        }
        let sceneChoices = s.choices.enumerated().map { idx, label in
            SceneChoice(id: "\(s.id)_c\(idx)", key: "\(idx)", label: label)
        }
        return GameScene(
            id: s.id, actIndex: 0, sceneType: s.sceneType,
            narrationSeed: s.narrationText,
            choices: sceneChoices, nextSceneIDs: s.nextSceneIDs,
            combat: combat, skillCheck: skillCheck, npcName: s.npcName
        )
    }
}
