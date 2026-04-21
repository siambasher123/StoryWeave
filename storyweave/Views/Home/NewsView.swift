import SwiftUI

struct NewsView: View {
    @StateObject private var viewModel = NewsViewModel()
    @State private var searchText = ""

    private var filteredArticles: [NewsArticle] {
        guard !searchText.isEmpty else { return viewModel.articles }
        let q = searchText.lowercased()
        return viewModel.articles.filter {
            $0.title.lowercased().contains(q) ||
            ($0.description?.lowercased().contains(q) ?? false) ||
            $0.source.name.lowercased().contains(q)
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.articles.isEmpty {
                ProgressView()
                    .tint(Color.swAccentPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.articles.isEmpty {
                errorState(message: error)
            } else {
                articlesList
            }
        }
        .task { await viewModel.load() }
    }

    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: swSpacing * 2) {
                SWSearchBar(placeholder: "Search news…", text: $searchText)
                    .padding(.horizontal, swSpacing * 2)
                    .padding(.top, swSpacing)

                if filteredArticles.isEmpty && !searchText.isEmpty {
                    SWEmptyStateView(
                        icon: "doc.text.magnifyingglass",
                        title: "No results",
                        subtitle: "Try a different keyword or source"
                    )
                    .frame(height: 280)
                } else {
                    ForEach(filteredArticles) { article in
                        NewsCardView(article: article)
                            .onAppear {
                                // Paginate on last unfiltered article (don't trigger while searching)
                                if searchText.isEmpty, article.id == viewModel.articles.last?.id {
                                    Task { await viewModel.loadNextPage() }
                                }
                            }
                    }
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.swAccentPrimary)
                            .padding()
                    }
                }
            }
            .padding(.horizontal, swSpacing * 2)
            .padding(.vertical, swSpacing)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: swSpacing * 2) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(Color.swTextSecondary)
            Text("Couldn't load news")
                .font(.swHeadline)
                .foregroundStyle(Color.swTextSecondary)
            Text(message)
                .font(.swCaption)
                .foregroundStyle(Color.swTextSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.refresh() }
            }
            .font(.swBody)
            .foregroundStyle(Color.swAccentPrimary)
        }
        .padding(swSpacing * 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
