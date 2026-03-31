import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var session: AppSession
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 56))
                        .foregroundColor(.indigo)
                        .padding(.bottom, 4)
                    Text("Create Account")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                    Text("Join StoryWeave today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 48)

                VStack(spacing: 16) {
                    InputField(icon: "envelope", placeholder: "Email", text: $email, isSecure: false, keyboardType: .emailAddress)
                    InputField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)
                    InputField(icon: "lock.rotation", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
                }
                .padding(.horizontal, 24)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                Button { register() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.indigo)
                            .frame(height: 54)
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account").font(.headline).foregroundColor(.white)
                        }
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?").foregroundColor(.secondary)
                        Text("Log In").fontWeight(.semibold).foregroundColor(.indigo)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
    }

    private func isValidEmail(_ value: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}")
        return predicate.evaluate(with: value)
    }

    private func register() {
        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        isLoading = true
        errorMessage = ""
        AuthService.shared.register(email: email, password: password) { result in
            switch result {
            case .failure(let error):
                isLoading = false
                errorMessage = error.localizedDescription
            case .success(let user):
                FirestoreService.shared.createUser(userId: user.userId, email: user.email) { _ in
                    isLoading = false
                    session.set(userId: user.userId, email: user.email)
                }
            }
        }
    }
}
