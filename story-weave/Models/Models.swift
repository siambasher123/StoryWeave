import Foundation

struct Story: Codable, Sendable {
    let storyId: String
    let title: String
    let startSceneId: String
    let scenes: [StoryScene]

    var sceneMap: [String: StoryScene] {
        Dictionary(uniqueKeysWithValues: scenes.map { ($0.id, $0) })
    }
}

struct StoryScene: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let choices: [Choice]

    var isEnding: Bool { choices.isEmpty }
}

struct Choice: Codable, Identifiable, Sendable {
    let id: String
    let text: String
    let nextSceneId: String
}

struct StoryMeta: Identifiable {
    let id: UUID
    let title: String
    let category: String
    let description: String
    let storyJsonURL: String
}

struct StorySession {
    let userId: String
    let storyId: UUID
    var currentSceneId: String
    var visitedSceneIds: [String]
    var chosenChoiceIds: [String]
    var isCompleted: Bool
    var totalScenes: Int?
    var updatedAt: Date

    var documentId: String { "\(userId)_\(storyId.uuidString)" }

    static func new(userId: String, storyId: UUID, startSceneId: String) -> StorySession {
        StorySession(
            userId: userId,
            storyId: storyId,
            currentSceneId: startSceneId,
            visitedSceneIds: [startSceneId],
            chosenChoiceIds: [],
            isCompleted: false,
            totalScenes: nil,
            updatedAt: Date()
        )
    }
}
