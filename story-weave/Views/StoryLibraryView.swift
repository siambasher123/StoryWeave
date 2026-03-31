import SwiftUI

struct StoryLibraryView: View {
    @StateObject var vm = StoryLibraryViewModel()
    @EnvironmentObject var session: AppSession
    @State var showingError = false

    var body: some View {
        VStack(spacing: 0) {

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search stories...", text: $vm.searchText)
                    .font(.subheadline)
                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Category filter
            CategoryFilterView(
                selected: $vm.selectedCategory,
                categories: vm.availableCategories
            )
            .padding(.bottom, 12)

            Divider()

            // Content
            VStack(alignment: .leading, spacing: 0) {
                // Title — always visible
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("Library")
                        .font(.system(size: 34, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                    if !vm.filteredStories.isEmpty {
                        Text("\(vm.filteredStories.count)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 8)

                if vm.isLoading {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView().scaleEffect(1.2)
                        Text("Loading stories...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                } else if vm.filteredStories.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No stories found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try a different search or category")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    Spacer()

                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(vm.filteredStories) { meta in
                                NavigationLink(destination: StoryPlayerView(meta: meta)) {
                                    // vm passed as @ObservedObject so the card reactively
                                    // shows Resume / Start Reading based on session state
                                    StoryCardView(meta: meta, vm: vm)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { vm.loadStories(userId: session.userId ?? "") }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onChange(of: vm.errorMessage) { _, msg in
            showingError = msg != nil
        }
    }
}
