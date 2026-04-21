import Foundation

struct NewsArticle: Codable, Identifiable, Sendable {
    var id: String { url }
    let source: NewsSource
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
}

struct NewsSource: Codable, Sendable {
    let id: String?
    let name: String
}

struct NewsResponse: Codable {
    let status: String
    let totalResults: Int?
    let articles: [NewsArticle]
    let message: String?
}
