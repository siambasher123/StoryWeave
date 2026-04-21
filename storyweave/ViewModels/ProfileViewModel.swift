import SwiftUI
import Combine
import PhotosUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPhoto: PhotosPickerItem?

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private let cloudinary = CloudinaryService.shared

    var email: String? { auth.currentUserEmail }

    func load() async {
        guard let uid = auth.currentUserID else { return }
        profile = try? await firestore.fetchUserProfile(uid: uid)
    }

    func updateDisplayName(_ name: String) async {
        guard var p = profile else { return }
        p.displayName = name
        do {
            try firestore.updateUserProfile(p)
            profile = p
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadAvatar(_ item: PhotosPickerItem) async {
        isLoading = true
        defer { isLoading = false }
        guard var p = profile,
              let data = try? await item.loadTransferable(type: Data.self) else { return }
        do {
            let url = try await cloudinary.upload(imageData: data)
            p.avatarURL = url.absoluteString
            try firestore.updateUserProfile(p)
            profile = p
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        try? auth.signOut()
    }
}
