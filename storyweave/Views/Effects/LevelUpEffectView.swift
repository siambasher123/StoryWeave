import SwiftUI

struct LevelUpEffectView: View {
    let level: Int

    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var textOffset: CGFloat = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    LinearGradient(colors: [Color.swAccentPrimary, Color.swAccentLight],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 4
                )
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
                .frame(width: 200, height: 200)

            VStack(spacing: swSpacing) {
                Text("LEVEL UP!")
                    .font(.swTitle)
                    .foregroundStyle(Color.swAccentLight)
                Text("Level \(level)")
                    .font(.swHeadline)
                    .foregroundStyle(Color.swTextPrimary)
            }
            .offset(y: textOffset)
            .opacity(textOpacity)
        }
        .accessibilityLabel("Level up! Now level \(level)")
        .task { await animate() }
    }

    private func animate() async {
        HapticEngine.play(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            ringScale = 1.5
            ringOpacity = 1
            textOpacity = 1
        }
        try? await Task.sleep(for: .milliseconds(500))
        withAnimation(.easeOut(duration: 1.5)) {
            ringOpacity = 0
            textOffset = -30
        }
    }
}
