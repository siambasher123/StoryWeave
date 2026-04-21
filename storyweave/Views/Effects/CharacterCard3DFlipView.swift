import SwiftUI

struct CharacterCard3DFlipView: View {
    let character: Character
    let role: CharacterRole
    let onSetPlayer: () -> Void

    @State private var rotation: Double = 0
    private var isFlipped: Bool { rotation >= 90 }

    var body: some View {
        ZStack {
            if !isFlipped {
                frontFace
                    .opacity(isFlipped ? 0 : 1)
            } else {
                backFace
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            HapticEngine.play(.impact(.light))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                rotation = isFlipped ? 0 : 180
            }
            if !isFlipped { onSetPlayer() }
        }
    }

    private var frontFace: some View {
        VStack(spacing: swSpacing) {
            ZStack {
                Circle()
                    .fill(archetypeColor.opacity(0.25))
                    .frame(width: 52, height: 52)
                Text(archetypeIcon)
                    .font(.title2)
            }

            Text(character.name)
                .font(.swHeadline)
                .foregroundStyle(Color.swTextPrimary)
                .lineLimit(1)

            Text(character.archetype.rawValue.capitalized)
                .font(.swCaption)
                .foregroundStyle(Color.swAccentLight)

            roleBadge
        }
        .frame(maxWidth: .infinity)
        .padding(swSpacing * 2)
        .background(Color.swSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(role == .hero ? Color.swWarning : Color.swAccentPrimary.opacity(0.3), lineWidth: role == .hero ? 2 : 1)
        )
    }

    private var backFace: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(character.name)
                .font(.swHeadline)
                .foregroundStyle(Color.swTextPrimary)
            Divider().background(Color.swSurfaceRaised)

            Group {
                statRow("HP", value: character.maxHP, color: .swSuccess)
                statRow("ATK", value: character.atk, color: .swAccentSecondary)
                statRow("DEF", value: character.def, color: .swAccentLight)
                statRow("DEX", value: character.dex, color: .swAccentHighlight)
                statRow("INT", value: character.intel, color: .swAccentPrimary)
            }

            Text(character.loreDescription)
                .font(.swCaption)
                .foregroundStyle(Color.swTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(swSpacing * 2)
        .background(Color.swSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.swAccentPrimary.opacity(0.4), lineWidth: 1)
        )
    }

    private func statRow(_ label: String, value: Int, color: Color) -> some View {
        HStack {
            Text(label).font(.swCaption).foregroundStyle(Color.swTextSecondary).frame(width: 28, alignment: .leading)
            Text("\(value)").font(.swCaption).fontWeight(.semibold).foregroundStyle(color)
        }
    }

    @ViewBuilder
    private var roleBadge: some View {
        switch role {
        case .hero:      SWPillBadge(text: "HERO ★", color: .swWarning)
        case .bot:       SWPillBadge(text: "BOT", color: .swAccentMuted)
        case .available: Color.clear.frame(height: 20)
        }
    }

    private var archetypeIcon: String {
        switch character.archetype {
        case .warrior: "⚔️"; case .mage: "🔮"; case .rogue: "🗡"
        case .cleric: "✨"; case .ranger: "🏹"; case .tank: "🛡"
        }
    }

    private var archetypeColor: Color {
        switch character.archetype {
        case .warrior: .swAccentSecondary; case .mage: .swAccentPrimary; case .rogue: .swTextSecondary
        case .cleric: .swSuccess; case .ranger: .swAccentHighlight; case .tank: .swAccentLight
        }
    }
}
