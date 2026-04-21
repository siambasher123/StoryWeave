import SwiftUI
import Combine

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = NewsService.shared
    private var currentPage = 1
    private var hasMore = true

    func load() async {
        guard articles.isEmpty else { return }
        await fetchPage(1)
    }

    func refresh() async {
        currentPage = 1
        hasMore = true
        articles = []
        await fetchPage(1)
    }

    func loadNextPage() async {
        guard hasMore, !isLoading else { return }
        await fetchPage(currentPage + 1)
    }

    private func fetchPage(_ page: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched = try await service.fetchNews(page: page)
            if page == 1 {
                articles = fetched
            } else {
                articles.append(contentsOf: fetched)
            }
            currentPage = page
            hasMore = !fetched.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
