import FirebaseAuth
import Foundation

class AuthService {
    static let shared = AuthService()
    private init() {}

    func register(
        email: String, password: String,
        completion: @escaping (Result<(userId: String, email: String), Error>) -> Void
    ) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                let err = NSError(
                    domain: "AuthService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Registration succeeded but no user was returned. Please try again."]
                )
                completion(.failure(err))
                return
            }
            completion(.success((userId: user.uid, email: user.email ?? "")))
        }
    }

    func login(
        email: String, password: String,
        completion: @escaping (Result<(userId: String, email: String), Error>) -> Void
    ) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                let err = NSError(
                    domain: "AuthService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Sign-in succeeded but no user was returned. Please try again."]
                )
                completion(.failure(err))
                return
            }
            completion(.success((userId: user.uid, email: user.email ?? "")))
        }
    }

    func logout() {
        try? Auth.auth().signOut()
    }

    func sendPasswordReset(
        email: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    var currentUser: (userId: String, email: String)? {
        guard let user = Auth.auth().currentUser else { return nil }
        return (userId: user.uid, email: user.email ?? "")
    }
}
