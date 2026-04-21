import Foundation
import UIKit

@MainActor
final class CloudinaryService {
    static let shared = CloudinaryService()

    private init() {}

    func upload(imageData: Data) async throws -> URL {
        let cloudName = SecretsManager.shared.cloudinaryCloudName
        let uploadPreset = SecretsManager.shared.cloudinaryUploadPreset

        guard !cloudName.isEmpty else { throw CloudinaryError.missingConfiguration }

        let compressed = compress(imageData, maxDimension: 800)

        let urlString = "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = buildMultipart(imageData: compressed, preset: uploadPreset, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let urlStr = json["secure_url"] as? String,
              let resultURL = URL(string: urlStr)
        else { throw CloudinaryError.invalidResponse }

        return resultURL
    }

    nonisolated private func compress(_ data: Data, maxDimension: CGFloat) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let compressed = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return compressed.jpegData(compressionQuality: 0.8) ?? data
    }

    nonisolated private func buildMultipart(imageData: Data, preset: String, boundary: String) -> Data {
        var body = Data()
        let crlf = "\r\n"
        func append(_ string: String) { body.append(Data(string.utf8)) }

        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"upload_preset\"\(crlf)\(crlf)")
        append("\(preset)\(crlf)")

        append("--\(boundary)\(crlf)")
        append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\(crlf)")
        append("Content-Type: image/jpeg\(crlf)\(crlf)")
        body.append(imageData)
        append("\(crlf)--\(boundary)--\(crlf)")

        return body
    }
}

enum CloudinaryError: Error, Sendable {
    case missingConfiguration
    case invalidResponse
}
