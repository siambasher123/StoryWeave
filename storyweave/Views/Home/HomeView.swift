import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedPost: Post?
    @State private var showCreatePost = false

    var body: some View {
        ZStack {
            Color.swBackground.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .tint(Color.swAccentPrimary)
            } else if viewModel.posts.isEmpty {
                VStack(spacing: swSpacing * 2) {
                    Text("No posts yet")
                        .font(.swHeadline)
                        .foregroundStyle(Color.swTextSecondary)
                    Text("Share your adventures!")
                        .font(.swBody)
                        .foregroundStyle(Color.swTextSecondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: swSpacing * 2) {
                        ForEach(viewModel.posts) { post in
                            PostCardView(
                                post: post,
                                isLiked: viewModel.likedPostIDs.contains(post.id),
                                onLike: { Task { await viewModel.toggleLike(post: post) } },
                                onTap:  { selectedPost = post }
                            )
                        }
                    }
                    .padding(swSpacing * 2)
                }
            }
        }
        .navigationTitle("Feed")
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
        .sheet(isPresented: $showCreatePost) { CreatePostView() }
        .task {
            viewModel.isLoading = true
            viewModel.startListening()
            await viewModel.loadLikedStatus()
        }
        .onDisappear { viewModel.stopListening() }
        .sheet(item: $selectedPost) { post in
            PostDetailView(post: post)
        }
    }
}
