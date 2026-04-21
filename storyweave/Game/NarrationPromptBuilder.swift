import Foundation

struct NarrationPrompt {
    let text: String
}

struct NarrationPromptBuilder {
    static func build(for scene: GameScene, actContext: Act?, partyState: [Character], decisionHistory: [String: String]) -> NarrationPrompt {
        let actLine = actContext.map { "Act: \($0.title) — \($0.theme)" } ?? "User-created story"
        var prompt = """
        You are narrating a D&D-style RPG called StoryWeave.
        \(actLine)
        Scene type: \(scene.sceneType.rawValue)
        Narration seed: \(scene.narrationSeed)

        Current party:
        \(partyState.map { "\($0.name) (\($0.archetype.rawValue)) HP:\($0.hp)/\($0.maxHP)" }.joined(separator: "\n"))

        """

        if !decisionHistory.isEmpty {
            prompt += "\nPrevious choices:\n"
            for (sceneID, choice) in decisionHistory {
                prompt += "- Scene \(sceneID): \(choice)\n"
            }
        }

        prompt += "\nWrite immersive narration (2-3 paragraphs). Match the dark fantasy tone. Do not repeat scene mechanics or show stats."

        return NarrationPrompt(text: prompt)
    }
}
