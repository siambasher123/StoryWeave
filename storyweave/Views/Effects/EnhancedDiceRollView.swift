import SwiftUI

struct EnhancedDiceRollView: View {
    let result: Int
    let onReveal: () -> Void

    @State private var displayValue = Int.random(in: 1...20)
    @State private var rotX: Double = 0
    @State private var rotY: Double = 0
    @State private var rotZ: Double = 0
    @State private var isRolling = true
    @State private var scale: CGFloat = 1
    @State private var wobble: Double = 0

    var body: some View {
        VStack(spacing: swSpacing * 2) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.swAccentDeep, Color.swSurface],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.swAccentPrimary.opacity(0.5), radius: 12)

                Canvas { context, size in
                    drawDiceFace(context: context, size: size, number: displayValue)
                }
                .frame(width: 100, height: 100)
                .rotation3DEffect(.degrees(rotX), axis: (x: 1, y: 0, z: 0))
                .rotation3DEffect(.degrees(rotY), axis: (x: 0, y: 1, z: 0))
                .rotation3DEffect(.degrees(rotZ), axis: (x: 0, y: 0, z: 1))
                .rotationEffect(.degrees(wobble))
            }
            .scaleEffect(scale)

            if !isRolling {
                Text("\(result)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(resultColor)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear { startRoll() }
    }

    private var resultColor: Color {
        switch result {
        case 20:         return .swWarning
        case 15...19:    return .swSuccess
        case 10...14:    return .swAccentHighlight
        case 5...9:      return .swWarning
        default:         return .swDanger
        }
    }

    private func startRoll() {
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) { rotX = 360 }
        withAnimation(.linear(duration: 1.7).repeatForever(autoreverses: false)) { rotY = 360 }
        withAnimation(.linear(duration: 2.3).repeatForever(autoreverses: false)) { rotZ = 360 }

        Task {
            for _ in 0..<25 {
                displayValue = Int.random(in: 1...20)
                try? await Task.sleep(for: .milliseconds(60))
            }
            displayValue = result
            isRolling = false

            // Wobble settle
            for amp in [8.0, -5.0, 3.0, -1.5, 0.0] {
                withAnimation(.easeInOut(duration: 0.12)) { wobble = amp }
                try? await Task.sleep(for: .milliseconds(130))
            }

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { scale = 1.2 }
            HapticEngine.play(.impact(.heavy))
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.spring()) { scale = 1 }
            onReveal()
        }
    }

    private func drawDiceFace(context: GraphicsContext, size: CGSize, number: Int) {
        let cx = size.width / 2, cy = size.height / 2
        let pipColor = GraphicsContext.Shading.color(Color.swAccentLight)

        func pip(at x: CGFloat, y: CGFloat) {
            context.fill(
                Path(ellipseIn: CGRect(x: cx + x - 4, y: cy + y - 4, width: 8, height: 8)),
                with: pipColor
            )
        }

        // Draw number text instead of pips for clarity on d20
        var ctx2 = context
        ctx2.opacity = 0.9
        // Use a simple representation: filled circle background + text-like mark
        let displayText = AttributedString(number > 0 ? "\(number)" : "?")
        context.draw(
            Text("\(number)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.swAccentLight),
            at: CGPoint(x: cx, y: cy),
            anchor: .center
        )
        // Corner pips for 1 or 20
        if number == 1 { pip(at: 0, y: 0) }
        if number == 20 {
            pip(at: -24, y: -24); pip(at: 24, y: -24)
            pip(at: -24, y: 24);  pip(at: 24, y: 24)
        }
    }
}
