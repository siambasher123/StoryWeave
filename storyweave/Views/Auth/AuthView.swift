import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showForgotPassword = false

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()
            AmbientParticleView()

            VStack(spacing: swSpacing * 4) {
                Spacer()

                VStack(spacing: swSpacing) {
                    Text("StoryWeave")
                        .font(.swDisplay)
                        .foregroundStyle(Color.swAccentPrimary)
                    Text("A D&D Adventure Awaits")
                        .font(.swBody)
                        .foregroundStyle(Color.swTextSecondary)
                }

                VStack(spacing: swSpacing * 2) {
                    VStack(alignment: .leading, spacing: 4) {
                        SWTextField(placeholder: "Email", text: $viewModel.email, isSecure: false)
                        if let err = viewModel.emailError {
                            Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        SWTextField(placeholder: "Password", text: $viewModel.password, isSecure: true)
                        if let err = viewModel.passwordError {
                            Text(err).font(.swCaption).foregroundStyle(Color.swDanger)
                        }
                    }

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.swCaption)
                            .foregroundStyle(Color.swDanger)
                    }

                    SWButton(title: viewModel.isLoading ? "Loading..." : "Sign In", style: .primary) {
                        Task { await viewModel.signIn() }
                    }
                    .disabled(viewModel.isLoading)

                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
                }
                .padding(.horizontal, swSpacing * 3)

                Spacer()

                Button("New to StoryWeave? Create Account") {
                    showSignUp = true
                }
                .font(.swBody)
                .foregroundStyle(Color.swAccentPrimary)
                .padding(.bottom, swSpacing * 3)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView(viewModel: viewModel)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(viewModel: viewModel)
        }
    }
}
