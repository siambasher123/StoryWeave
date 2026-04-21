import SwiftUI

struct ForgotPasswordView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            VStack(spacing: swSpacing * 4) {
                Text("Reset Password")
                    .font(.swTitle)
                    .foregroundStyle(Color.swTextPrimary)
                    .padding(.top, swSpacing * 4)

                Text("Enter your email to receive a reset link.")
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: swSpacing * 2) {
                    SWTextField(placeholder: "Email", text: $viewModel.email, isSecure: false)

                    if let msg = viewModel.errorMessage {
                        Text(msg)
                            .font(.swCaption)
                            .foregroundStyle(msg.contains("sent") ? Color.swSuccess : Color.swDanger)
                    }

                    SWButton(title: viewModel.isLoading ? "Sending..." : "Send Reset Email", style: .primary) {
                        Task { await viewModel.resetPassword() }
                    }
                    .disabled(viewModel.isLoading)

                    SWButton(title: "Cancel", style: .secondary) { dismiss() }
                }
                .padding(.horizontal, swSpacing * 3)

                Spacer()
            }
        }
    }
}
