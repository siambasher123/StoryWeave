import Combine
import Foundation

class StoryPlayerViewModel: ObservableObject {
    @Published var currentScene: StoryScene?
    @Published var visitedScenes: [StoryScene] = []   // exposed for SceneHistoryView
    @Published var visitedCount = 0
    @Published var totalScenes = 0
    @Published var isCompleted = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var story: Story?
    private var session: StorySession?

    func load(meta: StoryMeta, userId: String) {
        isLoading = true
        errorMessage = nil

        StoryAPIService.shared.fetchStory(from: meta.storyJsonURL) { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                self.isLoading = false
                self.errorMessage = error.localizedDescription

            case .success(let story):
                // Validate story structure before proceeding
                do {
                    try StoryValidator.validate(story)
                } catch {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    return
                }

                self.story = story
                self.totalScenes = story.scenes.count

                FirestoreService.shared.fetchSession(userId: userId, storyId: meta.id) {
                    [weak self] result in
                    guard let self else { return }
                    self.isLoading = false

                    switch result {
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription

                    case .success(let existingSession):
                        if var existing = existingSession {
                            // Backfill totalScenes if it was stored before we added the field
                            if existing.totalScenes == nil {
                                existing.totalScenes = story.scenes.count
                            }
                            self.session = existing
                        } else {
                            var newSession = StorySession.new(
                                userId: userId,
                                storyId: meta.id,
                                startSceneId: story.startSceneId
                            )
                            newSession.totalScenes = story.scenes.count
                            self.session = newSession
                        }
                        self.applySession()
                    }
                }
            }
        }
    }

    func makeChoice(_ choice: Choice, userId: String) {
        guard var session = session,
            let story = story,
            let nextScene = story.sceneMap[choice.nextSceneId]
        else { return }

        session.currentSceneId = nextScene.id

        if !session.visitedSceneIds.contains(nextScene.id) {
            session.visitedSceneIds.append(nextScene.id)
        }

        // Track every choice the user selected
        if !session.chosenChoiceIds.contains(choice.id) {
            session.chosenChoiceIds.append(choice.id)
        }

        if nextScene.isEnding {
            session.isCompleted = true
            isCompleted = true
        }

        session.updatedAt = Date()
        self.session = session
        currentScene = nextScene
        visitedCount = session.visitedSceneIds.count
        rebuildVisitedScenes()

        FirestoreService.shared.upsertSession(session) { _ in }
    }

    func restart(meta: StoryMeta, userId: String) {
        story = nil
        session = nil
        currentScene = nil
        visitedScenes = []
        visitedCount = 0
        totalScenes = 0
        isCompleted = false
        errorMessage = nil

        FirestoreService.shared.deleteSession(userId: userId, storyId: meta.id) { [weak self] _ in
            self?.load(meta: meta, userId: userId)
        }
    }

    // MARK: - Private

    private func applySession() {
        guard let session = session, let story = story else { return }
        currentScene = story.sceneMap[session.currentSceneId]
        visitedCount = session.visitedSceneIds.count
        isCompleted = session.isCompleted
        rebuildVisitedScenes()
    }

    /// Rebuilds the ordered list of visited StoryScene objects for SceneHistoryView.
    private func rebuildVisitedScenes() {
        guard let story = story, let session = session else { return }
        visitedScenes = session.visitedSceneIds.compactMap { story.sceneMap[$0] }
    }
}
