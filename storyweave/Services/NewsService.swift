import Foundation

@MainActor
final class NewsService {
    static let shared = NewsService()

    private let baseURL = "https://newsapi.org/v2/everything"
    private let query = "(gaming OR RPG OR tabletop OR \"board game\") OR (technology OR AI)"
    private let pageSize = 25

    private var apiKey: String {
        SecretsManager.shared.newsAPIKey
    }

    func fetchNews(page: Int = 1) async throws -> [NewsArticle] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "sortBy", value: "publishedAt"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "apiKey", value: apiKey)
        ]
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let msg = (try? JSONDecoder().decode(NewsResponse.self, from: data))?.message ?? "HTTP \(http.statusCode)"
            throw NSError(domain: "NewsService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }
        let decoded = try JSONDecoder().decode(NewsResponse.self, from: data)
        return decoded.articles.filter { !$0.title.isEmpty && $0.url != "[Removed]" }
    }
}
