import SwiftUI

// Defined outside so CharacterRowView can reference it without qualification issues
enum CharacterRole { case hero, bot, available }

struct PartySelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    @StateObject private var browserVM = CharacterBrowserViewModel()
    @State private var playerCharacterID: String?
    @State private var selectedBotIDs: [String] = []
    @State private var botCount: Int = 2
    @State private var useCardLayout: Bool = false

    private var canStart: Bool { playerCharacterID != nil }

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if browserVM.isLoading {
                    Spacer()
                    ProgressView().tint(Color.swAccentPrimary)
                    Spacer()
                } else {
                    botCountPicker
                        .padding(.horizontal, swSpacing * 2)
                        .padding(.vertical, swSpacing)

                    if playerCharacterID == nil {
                        instructionBanner
                    }

                    HStack {
                        Spacer()
                        Picker("Layout", selection: $useCardLayout) {
                            Image(systemName: "list.bullet").tag(false)
                            Image(systemName: "rectangle.grid.2x2").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                        .padding(.trailing, swSpacing * 2)
                    }

                    ScrollView {
                        if useCardLayout {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                      spacing: swSpacing * 2) {
                                ForEach(browserVM.characters) { character in
                                    CharacterCard3DFlipView(
                                        character: character,
                                        role: role(for: character),
                                        onSetPlayer: { setPlayer(character) }
                                    )
                                    .frame(height: 200)
                                }
                            }
                            .padding(.horizontal, swSpacing * 2)
                            .padding(.vertical, swSpacing)
                        } else {
                            LazyVStack(spacing: swSpacing) {
                                ForEach(browserVM.characters) { character in
                                    CharacterRowView(
                                        character: character,
                                        role: role(for: character),
                                        canAddBot: selectedBotIDs.count < botCount,
                                        onSetPlayer: { setPlayer(character) },
                                        onToggleBot: { toggleBot(character) }
                                    )
                                    .padding(.horizontal, swSpacing * 2)
                                }
                            }
                            .padding(.vertical, swSpacing)
                        }
                    }
                }

                beginButton
                    .padding(.horizontal, swSpacing * 2)
                    .padding(.bottom, swSpacing * 3)
            }
        }
        .task {
            await browserVM.load()
            autofillBots()
        }
        .onChange(of: botCount) { _, _ in autofillBots() }
        .onChange(of: playerCharacterID) { _, _ in autofillBots() }
    }

    // MARK: — Sub-views

    private var header: some View {
        VStack(spacing: swSpacing) {
            if let story = viewModel.pendingUserStory {
                SWPillBadge(text: "Community Story", color: .swAccentMuted)
                Text(story.title)
                    .font(.swTitle)
                    .foregroundStyle(Color.swTextPrimary)
                    .multilineTextAlignment(.center)
                Text("Choose your Hero and companions to play this story.")
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, swSpacing * 3)
            } else {
                Text("Assemble Your Party")
                    .font(.swTitle)
                    .foregroundStyle(Color.swTextPrimary)
                Text("Tap a character card to play as your Hero. Companions become bots.")
                    .font(.swBody)
                    .foregroundStyle(Color.swTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, swSpacing * 3)
            }
        }
        .padding(.top, swSpacing * 2)
        .padding(.bottom, swSpacing)
    }

    private var botCountPicker: some View {
        VStack(spacing: swSpacing) {
            HStack {
                Text("Bot Companions: \(botCount)")
                    .font(.swHeadline)
                    .foregroundStyle(Color.swTextPrimary)
                Spacer()
                Text("1 – 5")
                    .font(.swCaption)
                    .foregroundStyle(Color.swTextSecondary)
            }
            Slider(value: Binding(
                get: { Double(botCount) },
                set: { botCount = Int($0) }
            ), in: 1...5, step: 1)
            .tint(Color.swAccentPrimary)
            .accessibilityLabel("Number of bot companions: \(botCount)")
        }
    }

    private var instructionBanner: some View {
        HStack(spacing: swSpacing) {
            Image(systemName: "hand.tap.fill")
                .foregroundStyle(Color.swAccentHighlight)
            Text("Tap a card below to choose your Hero")
                .font(.swCaption)
                .foregroundStyle(Color.swAccentHighlight)
        }
        .padding(.horizontal, swSpacing * 3)
        .padding(.vertical, swSpacing)
        .background(Color.swAccentDeep.opacity(0.6), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, swSpacing * 2)
        .padding(.bottom, swSpacing)
    }

    private var beginButton: some View {
        SWButton(
            title: canStart ? "Begin Adventure" : "Select your Hero first",
            style: canStart ? .primary : .secondary
        ) {
            guard let playerID = playerCharacterID else { return }
            let bots = Array(selectedBotIDs.prefix(botCount))
            if let story = viewModel.pendingUserStory {
                viewModel.pendingUserStory = nil
                Task { await viewModel.startUserStory(story, playerCharacterID: playerID, botCharacterIDs: bots) }
            } else {
                Task { await viewModel.startNewGame(playerCharacterID: playerID, botCharacterIDs: bots) }
            }
        }
        .disabled(!canStart)
        .accessibilityLabel(canStart ? "Begin adventure" : "Select a hero to begin")
    }

    // MARK: — Logic

    private func role(for character: Character) -> CharacterRole {
        if character.id == playerCharacterID { return .hero }
        if selectedBotIDs.contains(character.id) { return .bot }
        return .available
    }

    private func setPlayer(_ character: Character) {
        if playerCharacterID == character.id {
            playerCharacterID = nil
        } else {
            selectedBotIDs.removeAll { $0 == character.id }
            playerCharacterID = character.id
        }
    }

    private func toggleBot(_ character: Character) {
        guard character.id != playerCharacterID else { return }
        if selectedBotIDs.contains(character.id) {
            selectedBotIDs.removeAll { $0 == character.id }
        } else if selectedBotIDs.count < botCount {
            selectedBotIDs.append(character.id)
        }
    }

    private func autofillBots() {
        let available = browserVM.characters.filter {
            $0.id != playerCharacterID && !selectedBotIDs.contains($0.id)
        }
        while selectedBotIDs.count > botCount {
            selectedBotIDs.removeLast()
        }
        for char in available {
            if selectedBotIDs.count >= botCount { break }
            selectedBotIDs.append(char.id)
        }
    }
}

// MARK: — Character Row

struct CharacterRowView: View {
    let character: Character
    let role: CharacterRole
    let canAddBot: Bool
    let onSetPlayer: () -> Void
    let onToggleBot: () -> Void

    var body: some View {
        Button(action: onSetPlayer) {
            SWCard {
                HStack(spacing: swSpacing * 2) {
                    archetypeAvatar

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: swSpacing) {
                            Text(character.name)
                                .font(.swHeadline)
                                .foregroundStyle(Color.swTextPrimary)
                            roleBadge
                        }
                        Text(character.archetype.rawValue.capitalized)
                            .font(.swCaption)
                            .foregroundStyle(Color.swAccentLight)
                        Text("HP \(character.hp) · ATK \(character.atk) · DEF \(character.def) · DEX \(character.dex)")
                            .font(.swCaption)
                            .foregroundStyle(Color.swTextSecondary)
                    }

                    Spacer()

                    rightControl
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: — Components

    private var archetypeAvatar: some View {
        ZStack {
            Circle()
                .fill(archetypeColor.opacity(0.25))
                .frame(width: 48, height: 48)
            Text(archetypeIcon)
                .font(.title2)
        }
    }

    @ViewBuilder
    private var roleBadge: some View {
        switch role {
        case .hero:
            SWPillBadge(text: "HERO ★", color: .swWarning)
        case .bot:
            SWPillBadge(text: "BOT", color: .swAccentMuted)
        case .available:
            EmptyView()
        }
    }

    @ViewBuilder
    private var rightControl: some View {
        switch role {
        case .hero:
            Image(systemName: "star.fill")
                .font(.title2)
                .foregroundStyle(Color.swWarning)

        case .bot:
            Button(action: onToggleBot) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.swAccentPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(character.name) from party")

        case .available:
            if canAddBot {
                Button(action: onToggleBot) {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundStyle(Color.swTextSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add \(character.name) as bot")
            } else {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundStyle(Color.swSurfaceRaised)
            }
        }
    }

    private var accessibilityLabel: String {
        switch role {
        case .hero:      return "\(character.name), your hero. Tap to deselect."
        case .bot:       return "\(character.name), bot companion. Tap card to set as hero."
        case .available: return "\(character.name), \(character.archetype.rawValue). Tap to set as hero."
        }
    }

    private var archetypeIcon: String {
        switch character.archetype {
        case .warrior: return "⚔️"
        case .mage:    return "🔮"
        case .rogue:   return "🗡"
        case .cleric:  return "✨"
        case .ranger:  return "🏹"
        case .tank:    return "🛡"
        }
    }

    private var archetypeColor: Color {
        switch character.archetype {
        case .warrior: return .swAccentSecondary
        case .mage:    return .swAccentPrimary
        case .rogue:   return .swTextSecondary
        case .cleric:  return .swSuccess
        case .ranger:  return .swAccentHighlight
        case .tank:    return .swAccentLight
        }
    }
}
