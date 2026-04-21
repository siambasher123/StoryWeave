import SwiftUI

enum CharacterAnimationState: Equatable, Sendable {
    case idle, attack, takeDamage, death, castSpell, heal, victory, taunt, defend
}

struct CharacterSpriteView: View {
    let emoji: String
    let state: CharacterAnimationState

    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    @State private var showRedFlash = false
    @State private var showGreenFlash = false
    @State private var showShield = false
    @State private var saturationVal: Double = 1

    var body: some View {
        ZStack {
            if showRedFlash {
                Text(emoji)
                    .font(.system(size: 44))
                    .colorMultiply(.red)
                    .opacity(0.6)
            }
            if showGreenFlash {
                Text(emoji)
                    .font(.system(size: 44))
                    .colorMultiply(.green)
                    .opacity(0.5)
            }

            Text(emoji)
                .font(.system(size: 44))
                .saturation(saturationVal)
                .rotationEffect(.degrees(rotation))
                .scaleEffect(scale)
                .opacity(opacity)
                .offset(x: xOffset, y: yOffset)

            if showShield {
                Text("🛡")
                    .font(.system(size: 20))
                    .offset(x: 16, y: 16)
            }
        }
        .onChange(of: state, initial: true) { _, newState in
            applyState(newState)
        }
    }

    private func applyState(_ s: CharacterAnimationState) {
        switch s {
        case .idle:
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                yOffset = -6
            }

        case .attack:
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                xOffset = -28
            }
            Task {
                try? await Task.sleep(for: .milliseconds(180))
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    xOffset = 0
                }
            }

        case .takeDamage:
            showRedFlash = true
            Task {
                for _ in 0..<3 {
                    withAnimation(.easeOut(duration: 0.06)) { xOffset = 8 }
                    try? await Task.sleep(for: .milliseconds(70))
                    withAnimation(.easeOut(duration: 0.06)) { xOffset = -8 }
                    try? await Task.sleep(for: .milliseconds(70))
                }
                withAnimation(.easeOut(duration: 0.06)) { xOffset = 0 }
                try? await Task.sleep(for: .milliseconds(200))
                showRedFlash = false
            }

        case .death:
            withAnimation(.easeOut(duration: 0.8)) {
                saturationVal = 0
                opacity = 0
                scale = 0.8
            }

        case .castSpell:
            withAnimation(.linear(duration: 0.5).repeatCount(2, autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 0.25).repeatCount(4, autoreverses: true)) {
                scale = 1.2
            }
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                rotation = 0
                scale = 1
                applyState(.idle)
            }

        case .heal:
            showGreenFlash = true
            withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                scale = 1.15
            }
            Task {
                try? await Task.sleep(for: .seconds(1))
                showGreenFlash = false
                scale = 1
                applyState(.idle)
            }

        case .victory:
            Task {
                for _ in 0..<3 {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { yOffset = -20 }
                    try? await Task.sleep(for: .milliseconds(250))
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { yOffset = 0 }
                    try? await Task.sleep(for: .milliseconds(250))
                }
                applyState(.idle)
            }

        case .taunt:
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                scale = 1.1
            }

        case .defend:
            showShield = true
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                scale = 1.15
            }
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                withAnimation(.spring()) { scale = 1 }
            }
        }
    }
}
