import SwiftUI

struct AuthView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var titleAppeared = false

    var body: some View {
        ZStack {
            LinearGradient.swGradientBackground.ignoresSafeArea()
            AmbientParticleView()

            VStack(spacing: swSpacing * 4) {
                Spacer()

                heroSection
                    .opacity(titleAppeared ? 1 : 0)
                    .offset(y: titleAppeared ? 0 : 20)
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: titleAppeared)

                formCard

                Spacer()

                Button("New to StoryWeave? Create Account") {
                    showSignUp = true
                }
                .font(.swBody)
                .foregroundStyle(Color.swAccentPrimary)
                .padding(.bottom, swSpacing * 3)
            }
        }
        .onAppear { titleAppeared = true }
        .sheet(isPresented: $showSignUp) { SignUpView(viewModel: viewModel) }
        .sheet(isPresented: $showForgotPassword) { ForgotPasswordView(viewModel: viewModel) }
    }

    // MARK: — Hero section

    private var heroSection: some View {
        VStack(spacing: swSpacing * 1.5) {
            // Branded emblem
            ZStack {
                Circle()
                    .fill(LinearGradient.swGradientPrimary)
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.swAccentPrimary.opacity(0.45), radius: 16, x: 0, y: 6)
                Image(systemName: "book.pages")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(Color.swGoldLight)
            }

            // Title with ambient glow
            Text("StoryWeave")
                .font(.swDisplay)
                .foregroundStyle(Color.swAccentPrimary)
                .background(
                    Ellipse()
                        .fill(Color.swAccentPrimary.opacity(0.18))
                        .blur(radius: 40)
                        .frame(width: 280, height: 100)
                        .offset(y: -10)
                )

            Text("A D&D Adventure Awaits")
                .font(.swBody)
                .foregroundStyle(Color.swTextSecondary)

            // Gold separator line
            Rectangle()
                .fill(LinearGradient.swGradientGold)
                .frame(width: 120, height: 1.5)
                .clipShape(Capsule())
        }
    }

    // MARK: — Form card

    private var formCard: some View {
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
        .padding(swSpacing * 2.5)
        .background(Color.swSurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.swAccentPrimary.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, swSpacing * 2)
    }
}
