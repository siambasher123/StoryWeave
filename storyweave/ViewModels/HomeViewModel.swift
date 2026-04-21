import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var likedPostIDs: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private var streamTask: Task<Void, Never>?

    func startListening() {
        streamTask = Task {
            for await posts in firestore.postsStream() {
                self.posts = posts
                isLoading = false
            }
        }
    }

    func stopListening() {
        streamTask?.cancel()
        streamTask = nil
    }

    func toggleLike(post: Post) async {
        guard let uid = auth.currentUserID else { return }
        let liked = likedPostIDs.contains(post.id)

        if liked { likedPostIDs.remove(post.id) } else { likedPostIDs.insert(post.id) }
        if let idx = posts.firstIndex(where: { $0.id == post.id }) {
            posts[idx].likeCount += liked ? -1 : 1
        }

        do {
            try await firestore.toggleLike(postID: post.id, uid: uid, currentlyLiked: liked)
        } catch {
            if liked { likedPostIDs.insert(post.id) } else { likedPostIDs.remove(post.id) }
            if let idx = posts.firstIndex(where: { $0.id == post.id }) {
                posts[idx].likeCount += liked ? 1 : -1
            }
            errorMessage = error.localizedDescription
        }
    }

    func loadLikedStatus() async {
        guard let uid = auth.currentUserID else { return }
        for post in posts {
            if let liked = try? await firestore.isPostLiked(postID: post.id, uid: uid), liked {
                likedPostIDs.insert(post.id)
            }
        }
    }
}
