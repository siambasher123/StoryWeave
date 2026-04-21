import SwiftUI
import FirebaseAuth

struct CommunityStoriesView: View {
    @StateObject private var vm = CommunityStoriesViewModel()
    @ObservedObject var gameVM: GameViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var myUID: String { Auth.auth().currentUser?.uid ?? "" }

    private var filtered: [UserStory] {
        guard !searchText.isEmpty else { return vm.stories }
        let q = searchText.lowercased()
        return vm.stories.filter {
            $0.title.lowercased().contains(q) ||
            $0.authorName.lowercased().contains(q) ||
            $0.synopsis.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.swGradientBackground.ignoresSafeArea()

                if vm.isLoading {
                    ProgressView().tint(Color.swAccentPrimary)
                } else if vm.stories.isEmpty {
                    SWEmptyStateView(
                        icon: "book.pages",
                        title: "No stories yet",
                        subtitle: "Published community stories appear here"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: swSpacing * 2) {
                            SWSearchBar(placeholder: "Search by title, author, or synopsis…", text: $searchText)
                                .padding(.horizontal, swSpacing * 2)
                                .padding(.top, swSpacing)

                            if filtered.isEmpty {
                                SWEmptyStateView(
                                    icon: "doc.text.magnifyingglass",
                                    title: "No matches",
                                    subtitle: "Try a different search"
                                )
                                .frame(height: 280)
                            } else {
                                ForEach(filtered) { story in
                                    StoryCard(story: story, isOwner: story.authorUID == myUID) {
                                        Task {
                                            try? await FirestoreService.shared.incrementPlayCount(storyID: story.id)
                                            gameVM.pendingUserStory = story
                                            dismiss()
                                        }
                                    } onDelete: {
                                        Task {
                                            try? await FirestoreService.shared.deleteUserStory(id: story.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, swSpacing * 2)
                        .padding(.bottom, swSpacing * 2)
                    }
                }
            }
            .navigationTitle("Community Stories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.foregroundStyle(Color.swAccentPrimary)
                }
            }
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}

private struct StoryCard: View {
    let story: UserStory
    let isOwner: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SWCard {
            VStack(alignment: .leading, spacing: swSpacing) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(story.title)
                            .font(.swHeadline).foregroundStyle(Color.swTextPrimary)
                        Text("by \(story.authorName)")
                            .font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundStyle(Color.swAccentPrimary)
                        Text("\(story.playCount)")
                            .font(.swCaption).foregroundStyle(Color.swTextSecondary)
                    }
                }

                if !story.synopsis.isEmpty {
                    Text(story.synopsis)
                        .font(.swBody).foregroundStyle(Color.swTextSecondary).lineLimit(3)
                }

                HStack {
                    SWPillBadge(text: "\(story.scenes.count) scenes", color: .swAccentMuted)
                    Spacer()
                    if isOwner {
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundStyle(Color.swDanger)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Delete story")
                        .padding(.trailing, swSpacing)
                    }
                    SWButton(title: "Play", style: .primary) { onPlay() }
                        .frame(width: 80)
                }
            }
        }
    }
}
