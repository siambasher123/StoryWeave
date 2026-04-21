import Combine
import Foundation

@MainActor
final class CommunityStoriesViewModel: ObservableObject {
    @Published var stories: [UserStory] = []
    @Published var isLoading = true

    private var streamTask: Task<Void, Never>?

    func start() {
        streamTask = Task {
            for await batch in FirestoreService.shared.publishedStoriesStream() {
                stories = batch
                isLoading = false
            }
        }
    }

    func stop() { streamTask?.cancel() }
}
