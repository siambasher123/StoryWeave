import SwiftUI

struct SpellEffectView: View {
    let archetype: Archetype
    @Binding var isActive: Bool

    @State private var ring1Scale: CGFloat = 0.1
    @State private var ring2Scale: CGFloat = 0.1
    @State private var ring1Opacity: Double = 0
    @State private var ring2Opacity: Double = 0
    @State private var slashOpacity: Double = 0
    @State private var beamWidth: CGFloat = 0

    var body: some View {
        ZStack {
            switch archetype {
            case .mage:
                mageEffect
            case .cleric:
                clericEffect
            case .rogue:
                rogueEffect
            case .warrior:
                warriorEffect
            case .ranger:
                rangerEffect
            case .tank:
                tankEffect
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { triggerEffect() }
        }
    }

    private var mageEffect: some View {
        ZStack {
            Circle()
                .stroke(Color.swAccentPrimary, lineWidth: 2)
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)
                .frame(width: 80, height: 80)
            Circle()
                .stroke(Color.swAccentLight, lineWidth: 1.5)
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)
                .frame(width: 60, height: 60)
        }
    }

    private var clericEffect: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Text("✦")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.swWarning)
                    .opacity(ring1Opacity)
                    .offset(x: cos(Double(i) * .pi / 4) * 30 * ring1Scale,
                            y: sin(Double(i) * .pi / 4) * 30 * ring1Scale)
            }
        }
    }

    private var rogueEffect: some View {
        ZStack {
            Capsule()
                .fill(Color.swTextSecondary.opacity(0.7))
                .frame(width: 40, height: 4)
                .rotationEffect(.degrees(45))
                .opacity(slashOpacity)
            Capsule()
                .fill(Color.swTextSecondary.opacity(0.5))
                .frame(width: 30, height: 3)
                .rotationEffect(.degrees(45))
                .offset(x: 8, y: 8)
                .opacity(slashOpacity)
        }
    }

    private var warriorEffect: some View {
        ZStack {
            Circle()
                .stroke(Color.swAccentSecondary, lineWidth: 3)
                .scaleEffect(ring1Scale)
                .opacity(ring1Opacity)
                .frame(width: 70, height: 70)
            Circle()
                .stroke(Color.swWarning, lineWidth: 2)
                .scaleEffect(ring2Scale)
                .opacity(ring2Opacity)
                .frame(width: 50, height: 50)
        }
    }

    private var rangerEffect: some View {
        Capsule()
            .fill(Color.swAccentHighlight)
            .frame(width: beamWidth, height: 4)
            .opacity(ring1Opacity)
    }

    private var tankEffect: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(Color.swAccentLight, lineWidth: 3)
            .scaleEffect(ring1Scale)
            .opacity(ring1Opacity)
            .frame(width: 50, height: 60)
    }

    private func triggerEffect() {
        switch archetype {
        case .mage:
            withAnimation(.easeOut(duration: 0.5)) { ring1Scale = 2; ring1Opacity = 0.8 }
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { ring2Scale = 2.5; ring2Opacity = 0.6 }
            withAnimation(.easeIn(duration: 0.3).delay(0.4)) { ring1Opacity = 0; ring2Opacity = 0 }
            Task { try? await Task.sleep(for: .milliseconds(800)); ring1Scale = 0.1; ring2Scale = 0.1; isActive = false }

        case .cleric:
            withAnimation(.easeOut(duration: 0.4)) { ring1Scale = 1; ring1Opacity = 1 }
            withAnimation(.easeIn(duration: 0.3).delay(0.5)) { ring1Opacity = 0 }
            Task { try? await Task.sleep(for: .milliseconds(900)); ring1Scale = 0; isActive = false }

        case .rogue:
            withAnimation(.easeIn(duration: 0.15)) { slashOpacity = 1 }
            withAnimation(.easeOut(duration: 0.2).delay(0.15)) { slashOpacity = 0 }
            Task { try? await Task.sleep(for: .milliseconds(500)); isActive = false }

        case .warrior:
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) { ring1Scale = 1.5; ring1Opacity = 1 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5).delay(0.1)) { ring2Scale = 1.8; ring2Opacity = 0.7 }
            withAnimation(.easeIn(duration: 0.25).delay(0.4)) { ring1Opacity = 0; ring2Opacity = 0 }
            Task { try? await Task.sleep(for: .milliseconds(750)); ring1Scale = 0.1; ring2Scale = 0.1; isActive = false }

        case .ranger:
            withAnimation(.linear(duration: 0.25)) { beamWidth = 100; ring1Opacity = 1 }
            withAnimation(.easeIn(duration: 0.2).delay(0.25)) { ring1Opacity = 0 }
            Task { try? await Task.sleep(for: .milliseconds(600)); beamWidth = 0; isActive = false }

        case .tank:
            withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) { ring1Scale = 1.2; ring1Opacity = 0.9 }
            Task { try? await Task.sleep(for: .seconds(1)); ring1Scale = 1; ring1Opacity = 0; isActive = false }
        }
    }
}
