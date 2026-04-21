import Foundation
import FirebaseAuth

@MainActor
final class AuthService {
    static let shared = AuthService()

    private init() {}

    var currentUserID: String? { Auth.auth().currentUser?.uid }
    var currentUserEmail: String? { Auth.auth().currentUser?.email }

    func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func signUp(email: String, password: String) async throws -> String {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user.uid
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func authStatePublisher() -> AsyncStream<String?> {
        AsyncStream { continuation in
            let handleBox = _SendableBox(Auth.auth().addStateDidChangeListener { _, user in
                continuation.yield(user?.uid)
            })
            continuation.onTermination = { _ in
                Auth.auth().removeStateDidChangeListener(handleBox.value)
            }
        }
    }
}

private final class _SendableBox<T>: @unchecked Sendable {
    nonisolated(unsafe) let value: T
    init(_ value: T) { self.value = value }
}
