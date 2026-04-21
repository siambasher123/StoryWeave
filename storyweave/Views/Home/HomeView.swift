import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var segment = 0
    @State private var selectedPost: Post?
    @State private var showCreatePost = false
    @State private var editingPost: Post?
    @State private var selectedConversation: Conversation?
    @State private var feedSearch = ""

    private var filteredPosts: [Post] {
        guard !feedSearch.isEmpty else { return viewModel.posts }
        let q = feedSearch.lowercased()
        return viewModel.posts.filter {
            $0.body.lowercased().contains(q) ||
            $0.authorName.lowercased().contains(q)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient.swGradientBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("", selection: $segment) {
                    Text("Feed").tag(0)
                    Text("Messages").tag(1)
                    Text("News").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, swSpacing * 2)
                .padding(.vertical, swSpacing)

                Divider().background(Color.swSurfaceRaised)

                if segment == 0 {
                    feedContent
                } else if segment == 1 {
                    ChatContentView(selectedConversation: $selectedConversation)
                } else {
                    NewsView()
                }
            }
        }
        .navigationTitle("Community")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCreatePost = true } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(Color.swAccentPrimary)
                }
                .accessibilityLabel("Create post")
            }
        }
        .navigationDestination(item: $selectedConversation) { conv in
            ConversationView(conversation: conv)
        }
        .sheet(isPresented: $showCreatePost) { CreatePostView() }
        .sheet(item: $editingPost) { post in CreatePostView(editing: post) }
        .sheet(item: $selectedPost) { post in PostDetailView(post: post) }
        .task {
            viewModel.isLoading = true
            viewModel.startListening()
            await viewModel.loadLikedStatus()
        }
        .onDisappear { viewModel.stopListening() }
    }

    // MARK: — Feed segment

    private var feedContent: some View {
        Group {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView()
                    .tint(Color.swAccentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.posts.isEmpty {
                SWEmptyStateView(
                    icon: "newspaper",
                    title: "No posts yet",
                    subtitle: "Share your adventures!"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: swSpacing * 2) {
                        SWSearchBar(placeholder: "Search posts…", text: $feedSearch)
                            .padding(.horizontal, swSpacing * 2)
                            .padding(.top, swSpacing)

                        if filteredPosts.isEmpty {
                            SWEmptyStateView(
                                icon: "doc.text.magnifyingglass",
                                title: "No results",
                                subtitle: "Try a different keyword or author name"
                            )
                            .frame(height: 280)
                        } else {
                            ForEach(filteredPosts) { post in
                                PostCardView(
                                    post: post,
                                    isLiked: viewModel.likedPostIDs.contains(post.id),
                                    currentUserID: viewModel.currentUserID,
                                    onLike:   { Task { await viewModel.toggleLike(post: post) } },
                                    onTap:    { selectedPost = post },
                                    onDelete: { Task { await viewModel.deletePost(post) } },
                                    onEdit:   { editingPost = post }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, swSpacing * 2)
                    .padding(.bottom, swSpacing * 2)
                }
            }
        }
    }
}
