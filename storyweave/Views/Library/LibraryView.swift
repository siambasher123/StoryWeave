import SwiftUI

struct LibraryView: View {
    @State private var segment = 0
    @State private var showCreateCharacter = false
    @State private var showCreateSkill = false
    @State private var showCreateStory = false

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text("Characters").tag(0)
                    Text("Skills").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, swSpacing * 2)
                .padding(.vertical, swSpacing)

                Divider().background(Color.swSurfaceRaised)

                if segment == 0 {
                    LibraryCharactersSection()
                } else {
                    LibrarySkillsSection()
                }
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showCreateCharacter = true } label: {
                        Label("Create Character", systemImage: "person.badge.plus")
                    }
                    Button { showCreateSkill = true } label: {
                        Label("Create Skill", systemImage: "wand.and.stars")
                    }
                    Button { showCreateStory = true } label: {
                        Label("Create Story", systemImage: "book.pages")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.swAccentPrimary)
                }
                .accessibilityLabel("Create")
            }
        }
        .sheet(isPresented: $showCreateCharacter) { CreateCharacterView() }
        .sheet(isPresented: $showCreateSkill) { CreateSkillView() }
        .sheet(isPresented: $showCreateStory) { CreateStoryView() }
    }
}

// MARK: - Embedded content (no inner NavigationStack)

private struct LibraryCharactersSection: View {
    @StateObject private var viewModel = CharacterBrowserViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().tint(Color.swAccentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.characters.isEmpty {
                emptyState
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
        .task { await viewModel.load() }
    }

    private var emptyState: some View {
        VStack(spacing: swSpacing * 2) {
            Image(systemName: "person.3").font(.system(size: 44)).foregroundStyle(Color.swTextSecondary)
            Text("No characters yet").font(.swHeadline).foregroundStyle(Color.swTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct LibrarySkillsSection: View {
    @StateObject private var viewModel = SkillBrowserViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().tint(Color.swAccentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.skills.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: swSpacing) {
                        ForEach(viewModel.skills) { skill in
                            SkillCardView(skill: skill)
                        }
                    }
                    .padding(swSpacing * 2)
                }
            }
        }
        .task { await viewModel.load() }
    }

    private var emptyState: some View {
        VStack(spacing: swSpacing * 2) {
            Image(systemName: "sparkles").font(.system(size: 44)).foregroundStyle(Color.swTextSecondary)
            Text("No skills yet").font(.swHeadline).foregroundStyle(Color.swTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
