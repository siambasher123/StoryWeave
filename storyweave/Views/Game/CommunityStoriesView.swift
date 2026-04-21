import SwiftUI
import FirebaseAuth

struct CommunityStoriesView: View {
    @StateObject private var vm = CommunityStoriesViewModel()
    @ObservedObject var gameVM: GameViewModel
    @Environment(\.dismiss) private var dismiss

    private var myUID: String { Auth.auth().currentUser?.uid ?? "" }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.swBackground.ignoresSafeArea()

                if vm.isLoading {
                    ProgressView().tint(Color.swAccentPrimary)
                } else if vm.stories.isEmpty {
                    VStack(spacing: swSpacing * 2) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 48)).foregroundStyle(Color.swAccentMuted)
                        Text("No published stories yet.")
                            .font(.swBody).foregroundStyle(Color.swTextSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: swSpacing * 2) {
                            ForEach(vm.stories) { story in
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
                        .padding(swSpacing * 2)
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
                        Button {
                            onDelete()
                        } label: {
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
