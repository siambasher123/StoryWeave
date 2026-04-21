import SwiftUI

struct SplashScreenView: View {
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.6
    @State private var titleOffset: CGFloat = 18
    @State private var titleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var particleOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient.swGradientBackground.ignoresSafeArea()

            // Ambient background blobs
            Circle()
                .fill(Color.swAccentPrimary.opacity(0.13))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -70, y: -130)

            Circle()
                .fill(Color.swAccentMuted.opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 70)
                .offset(x: 90, y: 140)

            VStack(spacing: swSpacing * 3.5) {
                // Logo mark
                ZStack {
                    // Outer diffuse glow
                    Circle()
                        .fill(Color.swAccentPrimary.opacity(0.18))
                        .frame(width: 150, height: 150)
                        .blur(radius: 28)
                        .scaleEffect(glowScale)

                    // Mid halo ring
                    Circle()
                        .stroke(Color.swAccentLight.opacity(0.20), lineWidth: 1.5)
                        .frame(width: 112, height: 112)

                    // Main gradient circle
                    Circle()
                        .fill(LinearGradient.swGradientPrimary)
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.swAccentPrimary.opacity(0.55), radius: 22, x: 0, y: 10)

                    // Icon
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                // Text stack
                VStack(spacing: swSpacing * 0.75) {
                    Text("StoryWeave")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.swAccentLight, Color.swTextPrimary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("YOUR ADVENTURE AWAITS")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.swTextSecondary)
                        .tracking(3)
                        .opacity(taglineOpacity)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .onAppear {
            // Icon springs in
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.1)) {
                iconScale = 1.0
                iconOpacity = 1.0
                glowScale = 1.0
            }
            // Title slides up
            withAnimation(.easeOut(duration: 0.45).delay(0.35)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
            // Tagline fades in last
            withAnimation(.easeIn(duration: 0.35).delay(0.6)) {
                taglineOpacity = 1.0
            }
        }
    }
}
