import Foundation

enum StoryValidationError: LocalizedError {
    case missingStartScene(sceneId: String)
    case brokenNextSceneLink(sceneId: String, choiceId: String, nextId: String)

    var errorDescription: String? {
        switch self {
        case .missingStartScene(let id):
            return "Start scene '\(id)' does not exist in this story."
        case .brokenNextSceneLink(let sceneId, let choiceId, let nextId):
            return "Choice '\(choiceId)' in scene '\(sceneId)' points to missing scene '\(nextId)'."
        }
    }
}

struct StoryValidator {
    static func validate(_ story: Story) throws {
        guard story.sceneMap[story.startSceneId] != nil else {
            throw StoryValidationError.missingStartScene(sceneId: story.startSceneId)
        }
        for scene in story.scenes {
            for choice in scene.choices {
                if story.sceneMap[choice.nextSceneId] == nil {
                    throw StoryValidationError.brokenNextSceneLink(
                        sceneId: scene.id,
                        choiceId: choice.id,
                        nextId: choice.nextSceneId
                    )
                }
            }
        }
    }
}
