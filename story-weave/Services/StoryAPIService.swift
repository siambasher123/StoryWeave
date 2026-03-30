import Foundation

class StoryAPIService {
    static let shared = StoryAPIService()
    private init() {}

    func fetchStory(from urlString: String, completion: @escaping (Result<Story, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(APIError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(AppConstants.jsonBinAPIKey, forHTTPHeaderField: "X-Access-Key")
        request.setValue("false", forHTTPHeaderField: "X-Bin-Meta")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                // Task { @MainActor in } is the Swift 6-correct way to hop to the
                // main actor from a nonisolated URLSession callback. DispatchQueue
                // is not actor-aware so Swift 6 still treats those closures as
                // nonisolated, which triggers the @MainActor conformance warning.
                Task { @MainActor in completion(.failure(error)) }
                return
            }
            guard let data = data else {
                Task { @MainActor in completion(.failure(APIError.noData)) }
                return
            }
            Task { @MainActor in
                do {
                    let story = try JSONDecoder().decode(Story.self, from: data)
                    completion(.success(story))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The story URL is invalid."
        case .noData: return "No data was returned from the server."
        }
    }
}
