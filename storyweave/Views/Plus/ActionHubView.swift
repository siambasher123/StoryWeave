import SwiftUI

struct ActionHubView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showCreatePost = false
    @State private var showCharacterBrowser = false
    @State private var showSkillBrowser = false
    @State private var showCreateCharacter = false
    @State private var showCreateSkill = false
    @State private var showCreateStory = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: swSpacing * 2) {
                        ActionRow(icon: "square.and.pencil", title: "Share a Post", subtitle: "Share your story with the world") {
                            showCreatePost = true
                        }
                        ActionRow(icon: "person.3.fill", title: "Browse Characters", subtitle: "Discover all characters") {
                            showCharacterBrowser = true
                        }
                        ActionRow(icon: "sparkles", title: "Browse Skills", subtitle: "Explore all available skills") {
                            showSkillBrowser = true
                        }
                        ActionRow(icon: "person.badge.plus", title: "Create Character", subtitle: "Build a new hero or companion") {
                            showCreateCharacter = true
                        }
                        ActionRow(icon: "wand.and.stars", title: "Create Skill", subtitle: "Design a unique ability") {
                            showCreateSkill = true
                        }
                        ActionRow(icon: "book.pages", title: "Create Story", subtitle: "Build your own RPG campaign") {
                            showCreateStory = true
                        }
                    }
                    .padding(swSpacing * 2)
                }
            }
            .navigationTitle("Actions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
        .sheet(isPresented: $showCreatePost) { CreatePostView() }
        .sheet(isPresented: $showCharacterBrowser) { CharacterBrowserView() }
        .sheet(isPresented: $showSkillBrowser) { SkillBrowserView() }
        .sheet(isPresented: $showCreateCharacter) { CreateCharacterView() }
        .sheet(isPresented: $showCreateSkill) { CreateSkillView() }
        .sheet(isPresented: $showCreateStory) { CreateStoryView() }
    }
}

struct ActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: swSpacing * 2) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.swAccentPrimary)
                    .frame(width: 44, height: 44)
                    .background(Color.swAccentPrimary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextPrimary)
                    Text(subtitle)
                        .font(.swCaption)
                        .foregroundStyle(Color.swTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.swTextSecondary)
            }
            .padding(swSpacing * 2)
            .background(Color.swSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityLabel(title)
    }
}
