import SwiftUI
import Combine
import PhotosUI

@MainActor
final class CreatePostViewModel: ObservableObject {
    @Published var body: String = ""
    @Published var selectedPhoto: PhotosPickerItem?
    @Published var attachedCharacterID: String?
    @Published var attachedSkillID: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didPost = false

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private let cloudinary = CloudinaryService.shared

    private let editingPost: Post?

    init(editing post: Post? = nil) {
        editingPost = post
        if let post {
            body = post.body
            attachedCharacterID = post.attachedCharacterID
            attachedSkillID = post.attachedSkillID
        }
    }

    var isEditing: Bool { editingPost != nil }

    func submit() async {
        guard !body.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Post cannot be empty."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if let existing = editingPost {
            await updateExisting(existing)
        } else {
            await createNew()
        }
    }

    private func createNew() async {
        guard let uid = auth.currentUserID else { return }
        let profile = try? await firestore.fetchUserProfile(uid: uid)

        var imageURL: String?
        if let photo = selectedPhoto,
           let data = try? await photo.loadTransferable(type: Data.self) {
            imageURL = try? await cloudinary.upload(imageData: data).absoluteString
        }

        let post = Post(
            id: UUID().uuidString,
            authorUID: uid,
            authorName: profile?.displayName ?? "Adventurer",
            body: body,
            imageURL: imageURL,
            attachedCharacterID: attachedCharacterID,
            attachedSkillID: attachedSkillID,
            timestamp: Date(),
            likeCount: 0
        )
        do {
            try firestore.createPost(post)
            didPost = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateExisting(_ existing: Post) async {
        var updated = existing
        updated.body = body
        updated.attachedCharacterID = attachedCharacterID
        updated.attachedSkillID = attachedSkillID

        if let photo = selectedPhoto,
           let data = try? await photo.loadTransferable(type: Data.self) {
            updated.imageURL = try? await cloudinary.upload(imageData: data).absoluteString
        }

        do {
            try firestore.updatePost(updated)
            didPost = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
