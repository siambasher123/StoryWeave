import Combine
import Foundation
import FirebaseAuth

@MainActor
final class StoryBuilderViewModel: ObservableObject {
    @Published var story: UserStory
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var didSave = false

    init() {
        let uid = Auth.auth().currentUser?.uid ?? ""
        let name = Auth.auth().currentUser?.displayName ?? "Unknown"
        story = UserStory(authorUID: uid, authorName: name)
    }

    // MARK: — Scene CRUD

    func addScene() {
        guard story.scenes.count < 40 else { return }
        let scene = UserStoryScene()
        story.scenes.append(scene)
        if story.startSceneID.isEmpty { story.startSceneID = scene.id }
    }

    func removeScene(id: String) {
        story.scenes.removeAll { $0.id == id }
        if story.startSceneID == id { story.startSceneID = story.scenes.first?.id ?? "" }
    }

    func updateScene(_ updated: UserStoryScene) {
        if let idx = story.scenes.firstIndex(where: { $0.id == updated.id }) {
            story.scenes[idx] = updated
        }
    }

    // MARK: — Validation

    var validationError: String? {
        if story.title.trimmingCharacters(in: .whitespaces).isEmpty { return "Title is required." }
        if story.scenes.isEmpty { return "Add at least one scene." }
        if story.startSceneID.isEmpty || !story.scenes.contains(where: { $0.id == story.startSceneID }) {
            return "Start scene must reference an existing scene."
        }
        for scene in story.scenes {
            for (_, nextID) in scene.nextSceneIDs where !nextID.isEmpty {
                if !story.scenes.contains(where: { $0.id == nextID }) {
                    return "Scene '\(scene.narrationText.prefix(20))' links to a non-existent scene."
                }
            }
        }
        return nil
    }

    var isValid: Bool { validationError == nil }

    // MARK: — Save / Publish

    func save() async {
        guard isValid else { saveError = validationError; return }
        isSaving = true
        do {
            try FirestoreService.shared.saveUserStory(story)
            didSave = true
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }

    func publish() async {
        guard isValid else { saveError = validationError; return }
        story.isPublished = true
        await save()
    }
}
