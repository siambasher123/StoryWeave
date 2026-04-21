import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            VStack(spacing: swSpacing * 4) {
                Text("Create Account")
                    .font(.swTitle)
                    .foregroundStyle(Color.swTextPrimary)
                    .padding(.top, swSpacing * 4)

                VStack(spacing: swSpacing * 2) {
                    VStack(alignment: .leading, spacing: 4) {
                        SWTextField(placeholder: "Display Name", text: $viewModel.displayName, isSecure: false)
                        if let err = viewModel.displayNameError {
                            Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        SWTextField(placeholder: "Email", text: $viewModel.email, isSecure: false)
                        if let err = viewModel.emailError {
                            Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        SWTextField(placeholder: "Password (6+ characters)", text: $viewModel.password, isSecure: true)
                        if let err = viewModel.passwordError {
                            Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
                        }
                    }

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.swCaption)
                            .foregroundStyle(Color.swDanger)
                    }

                    SWButton(title: viewModel.isLoading ? "Creating..." : "Create Account", style: .primary) {
                        Task {
                            await viewModel.signUp()
                            if viewModel.isSignedIn { dismiss() }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, swSpacing * 3)

                Spacer()
            }
        }
    }
}
