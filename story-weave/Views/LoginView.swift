import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: AppSession

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 10) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.indigo)
                            .padding(.bottom, 4)
                        Text("StoryWeave")
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundColor(.primary)
                        Text("Your interactive story library")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 48)

                    VStack(spacing: 16) {
                        InputField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email,
                            isSecure: false,
                            keyboardType: .emailAddress
                        )
                        InputField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password,
                            isSecure: true,
                            keyboardType: .default
                        )
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

                    Button {
                        login()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.indigo)
                                .frame(height: 54)
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Log In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Button {
                        showRegister = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundColor(.indigo)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarHidden(true)
            // Modern iOS 16+ replacement for NavigationLink(isActive:)
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        isLoading = true
        errorMessage = ""
        AuthService.shared.login(email: email, password: password) { result in
            isLoading = false
            switch result {
            case .success(let user):
                session.set(userId: user.userId, email: user.email)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}
