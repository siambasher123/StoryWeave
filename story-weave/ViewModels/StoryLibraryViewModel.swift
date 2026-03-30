import Combine
import Foundation

class StoryLibraryViewModel: ObservableObject {
    @Published var stories: [StoryMeta] = []
    @Published var sessions: [StorySession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedCategory = "All"

    var availableCategories: [String] {
        let unique = Array(Set(stories.map { $0.category })).sorted()
        return ["All"] + unique
    }

    var filteredStories: [StoryMeta] {
        stories.filter { meta in
            let matchesCategory = selectedCategory == "All" || meta.category == selectedCategory
            let matchesSearch =
                searchText.isEmpty || meta.title.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    /// Returns true when the user already has a session for the given story.
    func hasSession(for meta: StoryMeta) -> Bool {
        sessions.contains { $0.storyId == meta.id }
    }

    /// Fetches stories and the current user's sessions in parallel so StoryCardView
    /// can immediately show Resume vs Start Reading.
    func loadStories(userId: String) {
        isLoading = true
        errorMessage = nil

        let group = DispatchGroup()
        var fetchedStories: [StoryMeta] = []
        var fetchedSessions: [StorySession] = []
        var firstError: Error?

        group.enter()
        FirestoreService.shared.fetchAllStories { result in
            switch result {
            case .success(let s): fetchedStories = s
            case .failure(let e): firstError = e
            }
            group.leave()
        }

        group.enter()
        FirestoreService.shared.fetchUserSessions(userId: userId) { result in
            if case .success(let s) = result { fetchedSessions = s }
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.isLoading = false
            self.stories = fetchedStories
            self.sessions = fetchedSessions
            if let error = firstError { self.errorMessage = error.localizedDescription }
        }
    }
}
