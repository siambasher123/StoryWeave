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

    func submit() async {
        guard !body.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Post cannot be empty."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

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
}
