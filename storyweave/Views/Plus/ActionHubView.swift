import SwiftUI

// MARK: - Press animation style for CreateCard

private struct CreateCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - CreateTabView

struct CreateTabView: View {
    @State private var showCreatePost      = false
    @State private var showCreateCharacter = false
    @State private var showCreateSkill     = false
    @State private var showCreateStory     = false
    @State private var appeared            = false

    private let columns = [GridItem(.flexible(), spacing: swSpacing * 2),
                           GridItem(.flexible(), spacing: swSpacing * 2)]

    private let cards: [(icon: String, title: String, subtitle: String, color: Color)] = [
        ("square.and.pencil", "Post",      "Share your adventure", .swAccentPrimary),
        ("person.badge.plus", "Character", "Build a new hero",     .swAccentHighlight),
        ("wand.and.stars",    "Skill",     "Design an ability",    .swWarning),
        ("book.pages",        "Story",     "Write a campaign",     .swAccentSecondary)
    ]

    var body: some View {
        ZStack {
            LinearGradient.swGradientBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: swSpacing * 3) {
                    sectionHeader

                    LazyVGrid(columns: columns, spacing: swSpacing * 2) {
                        ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                            CreateCard(
                                icon: card.icon,
                                title: card.title,
                                subtitle: card.subtitle,
                                color: card.color
                            ) { handleTap(index: index) }
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.06),
                                value: appeared)
                        }
                    }
                }
                .padding(swSpacing * 2)
            }
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { appeared = true }
        .sheet(isPresented: $showCreatePost)      { CreatePostView() }
        .sheet(isPresented: $showCreateCharacter) { CreateCharacterView() }
        .sheet(isPresented: $showCreateSkill)     { CreateSkillView() }
        .sheet(isPresented: $showCreateStory)     { CreateStoryView() }
    }

    private var sectionHeader: some View {
        HStack(spacing: swSpacing) {
            Capsule()
                .fill(LinearGradient.swGradientPrimary)
                .frame(width: 3, height: 20)
            Text("What will you create today?")
                .font(.swBody)
                .foregroundStyle(Color.swTextSecondary)
            Spacer()
        }
    }

    private func handleTap(index: Int) {
        switch index {
        case 0: showCreatePost      = true
        case 1: showCreateCharacter = true
        case 2: showCreateSkill     = true
        default: showCreateStory    = true
        }
    }
}

// MARK: - CreateCard

struct CreateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: swSpacing * 1.5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.swGradientCard())
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }

                VStack(spacing: 3) {
                    Text(title)
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                    Text(subtitle)
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(swSpacing * 2)
            .background(LinearGradient.swGradientSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LinearGradient(
                        colors: [color.opacity(0.55), color.opacity(0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
            )
            .overlay(alignment: .top) {
                Capsule()
                    .fill(color.opacity(0.40))
                    .frame(height: 1.5)
                    .padding(.horizontal, 24)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(CreateCardPressStyle())
        .accessibilityLabel("Create \(title)")
    }
}
