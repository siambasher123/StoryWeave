import SwiftUI

struct LibraryView: View {
    @State private var segment = 0

    var body: some View {
        ZStack {
            LinearGradient.swGradientBackground.ignoresSafeArea()
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
    }
}

// MARK: - Characters Section

private struct LibraryCharactersSection: View {
    @StateObject private var viewModel = CharacterBrowserViewModel()
    @State private var editingCharacter: Character?
    @State private var searchText = ""

    private var filtered: [Character] {
        guard !searchText.isEmpty else { return viewModel.characters }
        let q = searchText.lowercased()
        return viewModel.characters.filter {
            $0.name.lowercased().contains(q) ||
            $0.archetype.rawValue.lowercased().contains(q)
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().tint(Color.swAccentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.characters.isEmpty {
                SWEmptyStateView(icon: "person.3", title: "No characters", subtitle: "Create one in the Create tab")
            } else {
                ScrollView {
                    LazyVStack(spacing: swSpacing) {
                        SWSearchBar(placeholder: "Search by name or archetype…", text: $searchText)
                            .padding(.horizontal, swSpacing * 2)
                            .padding(.top, swSpacing)

                        if filtered.isEmpty {
                            SWEmptyStateView(
                                icon: "doc.text.magnifyingglass",
                                title: "No results",
                                subtitle: "Try a different name or archetype"
                            )
                            .frame(height: 280)
                        } else {
                            ForEach(filtered) { character in
                                CharacterCardView(
                                    character: character,
                                    isOwn: character.createdByUID == viewModel.currentUserID,
                                    onEdit: { editingCharacter = character },
                                    onDelete: { Task { await viewModel.delete(character) } }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, swSpacing * 2)
                    .padding(.bottom, swSpacing * 2)
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $editingCharacter) { character in
            CreateCharacterView(editing: character)
        }
    }
}

// MARK: - Skills Section

private struct LibrarySkillsSection: View {
    @StateObject private var viewModel = SkillBrowserViewModel()
    @State private var editingSkill: Skill?
    @State private var searchText = ""

    private var filtered: [Skill] {
        guard !searchText.isEmpty else { return viewModel.skills }
        let q = searchText.lowercased()
        return viewModel.skills.filter {
            $0.name.lowercased().contains(q) ||
            $0.statAffected.rawValue.lowercased().contains(q) ||
            $0.description.lowercased().contains(q)
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().tint(Color.swAccentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.skills.isEmpty {
                SWEmptyStateView(icon: "sparkles", title: "No skills", subtitle: "Create one in the Create tab")
            } else {
                ScrollView {
                    LazyVStack(spacing: swSpacing) {
                        SWSearchBar(placeholder: "Search by name or stat…", text: $searchText)
                            .padding(.horizontal, swSpacing * 2)
                            .padding(.top, swSpacing)

                        if filtered.isEmpty {
                            SWEmptyStateView(
                                icon: "doc.text.magnifyingglass",
                                title: "No results",
                                subtitle: "Try a different name or stat"
                            )
                            .frame(height: 280)
                        } else {
                            ForEach(filtered) { skill in
                                SkillCardView(
                                    skill: skill,
                                    isOwn: skill.createdByUID == viewModel.currentUserID,
                                    onEdit: { editingSkill = skill },
                                    onDelete: { Task { await viewModel.delete(skill) } }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, swSpacing * 2)
                    .padding(.bottom, swSpacing * 2)
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $editingSkill) { skill in
            CreateSkillView(editing: skill)
        }
    }
}
