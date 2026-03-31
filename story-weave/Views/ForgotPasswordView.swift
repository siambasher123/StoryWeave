import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var isSuccess = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 56))
                        .foregroundColor(.indigo)
                        .padding(.bottom, 4)
                    Text("Reset Password")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                    Text("Enter your email to receive a reset link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.bottom, 48)

                InputField(
                    icon: "envelope",
                    placeholder: "Email",
                    text: $email,
                    isSecure: false,
                    keyboardType: .emailAddress
                )
                .padding(.horizontal, 24)

                Button { sendReset() } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.indigo)
                            .frame(height: 54)
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Reset Link").font(.headline).foregroundColor(.white)
                        }
                    }
                }
                .disabled(isLoading || isSuccess)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                if !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundColor(isSuccess ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }

                Button { dismiss() } label: {
                    Text("Back to Login")
                        .font(.subheadline)
                        .foregroundColor(.indigo)
                }
                .padding(.top, 20)
            }
        }
    }

    private func sendReset() {
        guard !email.isEmpty else {
            message = "Please enter your email address."
            isSuccess = false
            return
        }
        isLoading = true
        message = ""
        AuthService.shared.sendPasswordReset(email: email) { result in
            isLoading = false
            switch result {
            case .success:
                isSuccess = true
                message = "Check your inbox for a reset link."
            case .failure(let error):
                isSuccess = false
                message = error.localizedDescription
            }
        }
    }
}
