import SwiftUI

struct DiceRollView: View {
    let result: Int
    let onComplete: () -> Void

    @State private var rotation: Double = 0
    @State private var displayNumber: Int = 1
    @State private var scale: CGFloat = 1

    var body: some View {
        VStack(spacing: swSpacing * 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(colors: [Color.swAccentDeep, Color.swSurface],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.swAccentPrimary, lineWidth: 2)
                    )
                    .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 1, z: 0))
                    .scaleEffect(scale)

                Text("\(displayNumber)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.swAccentLight)
            }

            Text("d20")
                .font(.swCaption)
                .foregroundStyle(Color.swTextSecondary)
        }
        .accessibilityLabel("Dice roll result: \(result)")
        .task { await animate() }
    }

    private func animate() async {
        for _ in 0..<20 {
            guard !Task.isCancelled else { return }
            displayNumber = Int.random(in: 1...20)
            withAnimation(.linear(duration: 0.04)) { rotation += 36 }
            try? await Task.sleep(for: .milliseconds(50))
        }
        HapticEngine.play(.impact(.heavy))
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            displayNumber = result
            scale = 1.2
        }
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation { scale = 1 }
        onComplete()
    }
}
