import SwiftUI
import Combine

@MainActor
final class GameViewModel: ObservableObject {
    @Published var gameState: GameState?
    @Published var currentScene: GameScene?
    @Published var party: [Character] = []
    @Published var bots: [Character] = []
    @Published var narration: String = ""
    @Published var isLoadingNarration = false
    @Published var isGameOver = false
    @Published var isGameComplete = false
    @Published var combatLog: [String] = []
    @Published var showLevelUp = false
    @Published var lastPickedUpItem: InventoryItem?
    @Published var pendingUserStory: UserStory?

    var storyProvider: any StoryProvider = CampaignStoryProvider()

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private let gemini = GeminiService.shared
    private var narrationTask: Task<Void, Never>?
    private var sessionStart = Date()

    func loadGame() async {
        guard let uid = auth.currentUserID else { return }
        if let saved = try? await firestore.loadGameState(uid: uid) {
            gameState = saved
            isGameComplete = SceneManager.isComplete(saved)
            isGameOver     = SceneManager.isGameOver(saved)
        }
        await loadParty()
        if let state = gameState, !isGameComplete, !isGameOver {
            currentScene = storyProvider.scene(id: state.currentSceneID)
            await generateNarration()
        }
    }

    func startNewGame(playerCharacterID: String, botCharacterIDs: [String]) async {
        isGameComplete = false
        isGameOver = false
        combatLog = []
        currentScene = nil
        storyProvider = CampaignStoryProvider()
        let state = GameState.newGame(playerCharacterID: playerCharacterID,
                                     botCharacterIDs: botCharacterIDs)
        gameState = state
        sessionStart = Date()
        await loadParty()
        currentScene = storyProvider.scene(id: state.currentSceneID)
        autoSave()
        await generateNarration()
    }

    func startUserStory(_ story: UserStory, playerCharacterID: String, botCharacterIDs: [String]) async {
        storyProvider = UserStoryProvider(story: story)
        let state = GameState.newGame(playerCharacterID: playerCharacterID,
                                     botCharacterIDs: botCharacterIDs,
                                     startSceneID: story.startSceneID)
        gameState = state
        sessionStart = Date()
        isGameOver = false
        isGameComplete = false
        combatLog = []
        await loadParty()
        currentScene = storyProvider.scene(id: state.currentSceneID)
        // User stories aren't persisted in gameSaves to avoid overwriting campaign
        await generateNarration()
    }

    func makeChoice(_ choice: SceneChoice) async {
        guard var state = gameState, let scene = currentScene else { return }
        state.decisionHistory[scene.id] = choice.key
        gameState = state

        if let nextScene = SceneManager.advance(from: scene, choice: choice.key, in: state,
                                                provider: storyProvider) {
            currentScene = nextScene
            gameState?.currentSceneID = nextScene.id
            if nextScene.actIndex != scene.actIndex {
                gameState?.currentActIndex = nextScene.actIndex
                await trackActCompleted()
            }
            let updated = gameState!
            isGameOver     = SceneManager.isGameOver(updated)
            isGameComplete = SceneManager.isComplete(updated)
        } else if let nextID = scene.nextSceneIDs[choice.key] {
            gameState?.currentSceneID = nextID
            let updated = gameState!
            isGameComplete = SceneManager.isComplete(updated)
            isGameOver     = SceneManager.isGameOver(updated)
            autoSave()
            return
        }

        autoSave()
        await generateNarration()
    }

    func resolveSkillCheck(stat: StatType, dc: Int, roll: Int) async -> (outcome: CombatOutcome, nextSceneID: String?) {
        guard let scene = currentScene, let config = scene.skillCheck,
              let player = party.first(where: { $0.id == gameState?.playerCharacterID }) else {
            return (.fail, nil)
        }
        let (outcome, _) = CombatEngine.resolveSkillCheck(character: player, stat: stat, difficulty: dc)
        await trackSkillCheck(passed: outcome == .success || outcome == .criticalSuccess || outcome == .partialSuccess)
        let nextID = (outcome == .fail || outcome == .criticalFail)
            ? config.failureSceneID
            : config.successSceneID
        return (outcome, nextID)
    }

    func advanceToScene(_ sceneID: String) async {
        guard var state = gameState else { return }
        state.currentSceneID = sceneID
        gameState = state
        if let next = storyProvider.scene(id: sceneID) {
            currentScene = next
            if next.actIndex != state.currentActIndex {
                gameState?.currentActIndex = next.actIndex
            }
            isGameOver     = SceneManager.isGameOver(state)
            isGameComplete = SceneManager.isComplete(state)
        }
        autoSave()
        await generateNarration()
    }

    func resolveCombatVictory() async {
        guard var state = gameState else { return }
        let deadIDs = party.filter({ $0.hp <= 0 }).map(\.id)
        for deadID in deadIDs {
            state.survivingCharacterIDs.removeAll { $0 == deadID }
        }
        let xpGain = 100 + (deadIDs.count * 25)
        state.playerXP += xpGain
        let newLevel = 1 + state.playerXP / 300
        if newLevel > state.playerLevel {
            state.playerLevel = newLevel
            showLevelUp = true
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                showLevelUp = false
            }
        }
        gameState = state
        await trackCombatWon(charactersLost: deadIDs.count)
        await makeChoice(SceneChoice(id: "v", key: "victory", label: "Victory"))
    }

    func resolveCombatDefeat() async {
        await trackCombatLost()
        gameState?.currentSceneID = "game_over"
        isGameOver = true
        autoSave()
    }

    func restart() async {
        guard let pid = gameState?.playerCharacterID,
              let botIDs = gameState?.botCharacterIDs else { return }
        isGameOver = false
        isGameComplete = false
        combatLog = []
        storyProvider = CampaignStoryProvider()
        await startNewGame(playerCharacterID: pid, botCharacterIDs: botIDs)
    }

    // MARK: - Party loading

    private func loadParty() async {
        guard let state = gameState else { return }
        party = []
        bots  = []
        for id in state.partyCharacterIDs {
            if let char = try? await firestore.fetchCharacter(id: id) {
                party.append(char)
                if state.botCharacterIDs.contains(id) {
                    bots.append(char)
                }
            }
        }
    }

    // MARK: - Narration

    private func generateNarration() async {
        guard let scene = currentScene, let state = gameState else { return }

        isLoadingNarration = true
        narration = ""
        narrationTask?.cancel()

        let act = SceneManager.currentAct(for: state)
        let prompt = NarrationPromptBuilder.build(
            for: scene, actContext: act, partyState: party, decisionHistory: state.decisionHistory
        )

        narrationTask = Task {
            do {
                let stream = try await gemini.generateNarration(prompt: prompt.text)
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    narration += chunk
                }
            } catch {
                if narration.isEmpty { narration = scene.narrationSeed }
            }
            isLoadingNarration = false
        }
    }

    // MARK: - Analytics helpers

    func trackSkillCheckPublic(passed: Bool) async {
        await trackSkillCheck(passed: passed)
    }

    private func trackCombatWon(charactersLost: Int) async {
        guard let uid = auth.currentUserID,
              var profile = try? await firestore.fetchUserProfile(uid: uid) else { return }
        profile.gameStats.combatsWon += 1
        profile.gameStats.charactersLost += charactersLost
        try? firestore.updateUserProfile(profile)
    }

    private func trackCombatLost() async {
        guard let uid = auth.currentUserID,
              var profile = try? await firestore.fetchUserProfile(uid: uid) else { return }
        profile.gameStats.combatsLost += 1
        try? firestore.updateUserProfile(profile)
    }

    private func trackSkillCheck(passed: Bool) async {
        guard let uid = auth.currentUserID,
              var profile = try? await firestore.fetchUserProfile(uid: uid) else { return }
        profile.gameStats.skillChecksAttempted += 1
        if passed { profile.gameStats.skillChecksPassed += 1 }
        try? firestore.updateUserProfile(profile)
    }

    private func trackActCompleted() async {
        guard let uid = auth.currentUserID,
              var profile = try? await firestore.fetchUserProfile(uid: uid) else { return }
        profile.gameStats.actsCompleted += 1
        try? firestore.updateUserProfile(profile)
    }

    // MARK: - Autosave

    private func autoSave() {
        guard let state = gameState, let uid = auth.currentUserID,
              state.customStartSceneID == nil else { return }  // don't overwrite campaign save with user story
        try? firestore.saveGameState(state, for: uid)
    }
}
