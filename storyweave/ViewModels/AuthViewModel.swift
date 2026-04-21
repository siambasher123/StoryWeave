import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var email: String = "" {
        didSet { emailValidator = email }
    }
    @Published var password: String = "" {
        didSet { passwordValidator = password }
    }
    @Published var displayName: String = "" {
        didSet { displayNameValidator = displayName }
    }

    @Validated(validate: { $0.contains("@") && $0.count > 3 ? nil : "Enter a valid email" })
    private var emailValidator: String = ""

    @Validated(validate: { $0.count >= 6 ? nil : "Password must be at least 6 characters" })
    private var passwordValidator: String = ""

    @Validated(validate: { $0.trimmingCharacters(in: .whitespaces).count >= 2 ? nil : "Name must be at least 2 characters" })
    private var displayNameValidator: String = ""

    var emailError: String? { email.isEmpty ? nil : $emailValidator.errorMessage }
    var passwordError: String? { password.isEmpty ? nil : $passwordValidator.errorMessage }
    var displayNameError: String? { displayName.isEmpty ? nil : $displayNameValidator.errorMessage }

    private let auth = AuthService.shared
    private let firestore = FirestoreService.shared

    init() {
        Task { await observeAuthState() }
    }

    private func observeAuthState() async {
        for await uid in auth.authStatePublisher() {
            isSignedIn = uid != nil
        }
    }

    func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            let uid = try await auth.signUp(email: email, password: password)
            let profile = UserProfile(
                id: uid,
                displayName: displayName.isEmpty ? "Adventurer" : displayName,
                avatarURL: nil,
                createdAt: Date(),
                gameStats: .empty
            )
            try firestore.createUserProfile(profile)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func resetPassword() async {
        isLoading = true
        errorMessage = nil
        do {
            try await auth.resetPassword(email: email)
            errorMessage = "Reset email sent."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        try? auth.signOut()
    }
}
