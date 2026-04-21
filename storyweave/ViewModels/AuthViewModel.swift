import SwiftUI
import Combine

/// ViewModel managing user authentication flows and state
/// Handles sign in, sign up, password reset, and real-time auth state monitoring
/// Validates user input and manages loading/error states for UI binding
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published State Properties
    
    /// Current signed-in status - used to determine which view to show
    /// true = user is authenticated, false = show auth screen
    @Published var isSignedIn = false
    
    /// Loading state for authentication operations
    /// true while API requests are in progress, false when complete
    @Published var isLoading = false
    
    /// Error message from authentication failures
    /// Displayed in UI when sign in, sign up, or password reset fails
    @Published var errorMessage: String?

    // MARK: - Input Properties
    
    /// User's email input
    /// Triggers emailValidator when changed for real-time validation
    @Published var email: String = "" {
        didSet { emailValidator = email }
    }
    
    /// User's password input
    /// Triggers passwordValidator when changed for real-time validation
    @Published var password: String = "" {
        didSet { passwordValidator = password }
    }
    
    /// User's display name input (registration only)
    /// Triggers displayNameValidator when changed for real-time validation
    @Published var displayName: String = "" {
        didSet { displayNameValidator = displayName }
    }

    // MARK: - Validation Properties
    
    /// Validated email using @Validated property wrapper
    /// Rules: Must contain '@' and be longer than 3 characters
    @Validated(validate: { $0.contains("@") && $0.count > 3 ? nil : "Enter a valid email" })
    private var emailValidator: String = ""

    /// Validated password using @Validated property wrapper
    /// Rules: Must be at least 6 characters long
    @Validated(validate: { $0.count >= 6 ? nil : "Password must be at least 6 characters" })
    private var passwordValidator: String = ""

    /// Validated display name using @Validated property wrapper
    /// Rules: Must be at least 2 characters (after trimming whitespace)
    @Validated(validate: { $0.trimmingCharacters(in: .whitespaces).count >= 2 ? nil : "Name must be at least 2 characters" })
    private var displayNameValidator: String = ""

    /// Error message for email field, only shown if email is not empty
    /// Returns validation error or nil if valid
    var emailError: String? { email.isEmpty ? nil : $emailValidator.errorMessage }
    
    /// Error message for password field, only shown if password is not empty
    /// Returns validation error or nil if valid
    var passwordError: String? { password.isEmpty ? nil : $passwordValidator.errorMessage }
    
    /// Error message for display name field, only shown if name is not empty
    /// Returns validation error or nil if valid
    var displayNameError: String? { displayName.isEmpty ? nil : $displayNameValidator.errorMessage }

    // MARK: - Dependencies
    
    /// Shared authentication service for Firebase Auth operations
    private let auth = AuthService.shared
    
    /// Shared Firestore service for user profile creation
    private let firestore = FirestoreService.shared

    // MARK: - Initialization
    
    /// Initializes the view model and starts observing auth state changes
    /// Sets up listener for real-time user authentication status updates
    init() {
        Task { await observeAuthState() }
    }

    // MARK: - Auth State Management
    
    /// Observes Firebase authentication state changes in real-time
    /// Updates isSignedIn whenever user logs in or out
    /// Runs continuously as async stream subscription
    private func observeAuthState() async {
        for await uid in auth.authStatePublisher() {
            isSignedIn = uid != nil
        }
    }

    // MARK: - Authentication Methods
    
    /// Signs in an existing user with email and password
    /// Sets loading state, clears errors, attempts authentication
    /// On success: auth service updates Firebase session
    /// On failure: displays error message in errorMessage field
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

    /// Creates a new user account and initializes profile
    /// Steps:
    ///   1. Creates Firebase Auth account with email/password
    ///   2. Creates UserProfile in Firestore with registration data
    ///   3. Defaults display name to "Adventurer" if not provided
    /// Sets loading state, clears errors, handles both operations atomically
    /// On failure: displays error message in errorMessage field
    func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            // Create Firebase Auth account
            let uid = try await auth.signUp(email: email, password: password)
            
            // Create user profile document in Firestore
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

    /// Sends a password reset email to the user's email address
    /// User follows link in email to set a new password
    /// Sets loading state, clears errors, displays confirmation message on success
    /// On failure: displays error message in errorMessage field
    func resetPassword() async {
        isLoading = true
        errorMessage = nil
        do {
            try await auth.resetPassword(email: email)
            // Show confirmation message instead of error
            errorMessage = "Reset email sent."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Signs out the current user from Firebase Auth
    /// Clears auth session and local state updates via observeAuthState
    /// Errors are silently ignored - sign out always succeeds at UI level
    func signOut() {
        try? auth.signOut()
    }
}
