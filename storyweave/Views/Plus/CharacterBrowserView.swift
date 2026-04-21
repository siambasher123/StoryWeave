import SwiftUI

struct CharacterBrowserView: View {
    @StateObject private var viewModel = CharacterBrowserViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView().tint(Color.swAccentPrimary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: swSpacing) {
                            ForEach(viewModel.characters) { character in
                                CharacterCardView(character: character)
                            }
                        }
                        .padding(swSpacing * 2)
                    }
                }
            }
            .navigationTitle("Characters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
        .task { await viewModel.load() }
    }
}

// MARK: - Character Card (used in Library + browser)

struct CharacterCardView: View {
    let character: Character
    var isOwn: Bool = false
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        SWCard {
            HStack(spacing: swSpacing * 2) {
                portraitView
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(character.name)
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                    Text(character.archetype.rawValue.capitalized)
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                    HStack(spacing: swSpacing) {
                        StatBadge(label: "HP", value: character.hp)
                        StatBadge(label: "ATK", value: character.atk)
                        StatBadge(label: "DEF", value: character.def)
                    }
                }

                Spacer()

                if isOwn {
                    VStack(spacing: swSpacing) {
                        if let onEdit {
                            Button(action: onEdit) {
                                Image(systemName: "pencil.circle")
                                    .foregroundStyle(Color.swAccentPrimary)
                            }
                            .accessibilityLabel("Edit character")
                        }
                        if let onDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash.circle")
                                    .foregroundStyle(Color.swDanger)
                            }
                            .accessibilityLabel("Delete character")
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var portraitView: some View {
        if let urlString = character.portraitURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                archetypeIcon
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            archetypeIcon
        }
    }

    private var archetypeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.swAccentDeep)
                .frame(width: 52, height: 52)
            Text(archetypeEmoji)
                .font(.system(size: 28))
        }
    }

    private var archetypeEmoji: String {
        switch character.archetype {
        case .warrior: return "⚔️"
        case .mage:    return "🔮"
        case .rogue:   return "🗡"
        case .cleric:  return "✨"
        case .ranger:  return "🏹"
        case .tank:    return "🛡"
        }
    }
}

struct StatBadge: View {
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.swCaption)
                .foregroundStyle(Color.swTextPrimary)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.swTextSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.swBackground)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
