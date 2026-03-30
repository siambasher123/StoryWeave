import Combine
import Foundation

class ProfileViewModel: ObservableObject {
    @Published var sessions: [StorySession] = []
    @Published var stories: [StoryMeta] = []
    @Published var isLoading = false

    var storiesStarted: Int { sessions.count }
    var storiesCompleted: Int { sessions.filter { $0.isCompleted }.count }

    func titleForSession(_ session: StorySession) -> String {
        stories.first { $0.id == session.storyId }?.title ?? session.storyId.uuidString
    }

    func loadSessions(userId: String) {
        isLoading = true
        FirestoreService.shared.fetchAllStories { [weak self] result in
            guard let self else { return }
            if case .success(let stories) = result {
                self.stories = stories
            }
            FirestoreService.shared.fetchUserSessions(userId: userId) { [weak self] result in
                guard let self else { return }
                self.isLoading = false
                if case .success(let sessions) = result {
                    self.sessions = sessions
                }
            }
        }
    }

    func deleteSession(userId: String, storyId: UUID) {
        FirestoreService.shared.deleteSession(userId: userId, storyId: storyId) { [weak self] _ in
            self?.sessions.removeAll { $0.storyId == storyId }
        }
    }

    func logout(session: AppSession) {
        AuthService.shared.logout()
        session.clear()
    }
}
