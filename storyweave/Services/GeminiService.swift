import Foundation

/// AI-powered narration generation service using Google Gemini API
/// Generates dynamic story narration based on game context and events
/// Uses server-sent events (SSE) for streaming responses
@MainActor
final class GeminiService {
    /// Shared singleton instance for app-wide AI narration access
    static let shared = GeminiService()

    /// Google Generative Language API endpoint for streaming content generation
    /// Uses Gemini 2.0 Flash model for fast, cost-effective response generation
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent"

    private init() {}

    /// Generates dynamic AI narration using Gemini API with streaming response
    /// 
    /// If no API key is configured, returns a fallback narration to allow offline gameplay
    /// Uses server-sent events (SSE) protocol for real-time text streaming
    /// Each SSE event contains one chunk of the AI-generated text
    /// 
    /// - Parameter prompt: The narration prompt describing the scene/event to narrate
    ///   Example: "A party of adventurers enters a dark forest filled with ancient trees..."
    /// 
    /// - Returns: AsyncThrowingStream<String, Error> yielding individual text chunks
    ///   Consumer receives chunks as they stream in for real-time display
    /// 
    /// - Throws: URLError if URL is invalid or network request fails
    ///          If HTTP status is not 200, throws badServerResponse error
    func generateNarration(prompt: String) async throws -> AsyncThrowingStream<String, Error> {
        // Retrieve the Gemini API key from secure secrets manager
        let apiKey = SecretsManager.shared.geminiAPIKey
        
        // Fallback to default narration if no API key is available
        // Allows gameplay to continue even without AI narration service
        guard !apiKey.isEmpty else {
            return AsyncThrowingStream { continuation in
                continuation.yield("The shadows stir as your party advances...")
                continuation.finish()
            }
        }

        // Build the full API endpoint URL with authentication key
        let urlString = "\(baseURL)?key=\(apiKey)&alt=sse"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        // Configure HTTP POST request with JSON body
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Format prompt into Gemini API request structure
        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Execute streaming request - receives response body as stream of bytes
        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        
        // Validate successful response from API
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Return async stream for real-time text chunk consumption
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    // Process server-sent events line by line
                    for try await line in bytes.lines {
                        // SSE format: "data: {json content}"
                        guard line.hasPrefix("data: ") else { continue }
                        
                        // Extract JSON payload from SSE event
                        let jsonStr = String(line.dropFirst(6))
                        guard let data = jsonStr.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              // Navigate Gemini response structure: candidates[0].content.parts[0].text
                              let candidates = json["candidates"] as? [[String: Any]],
                              let content = candidates.first?["content"] as? [String: Any],
                              let parts = content["parts"] as? [[String: Any]],
                              let text = parts.first?["text"] as? String
                        else { continue }
                        
                        // Yield text chunk to consumer for display
                        continuation.yield(text)
                    }
                    // Signal successful completion of stream
                    continuation.finish()
                } catch {
                    // Forward any stream processing errors to consumer
                    continuation.finish(throwing: error)
                }
            }
        }
    }
