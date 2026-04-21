import Foundation

struct SecretsManager {
    static let shared = SecretsManager()

    private let dict: [String: Any]

    private init() {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let d = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            dict = [:]
            return
        }
        dict = d
    }

    var geminiAPIKey: String { (dict["GeminiAPIKey"] as? String) ?? "" }
    var cloudinaryCloudName: String { (dict["CloudinaryCloudName"] as? String) ?? "" }
    var cloudinaryUploadPreset: String { (dict["CloudinaryUploadPreset"] as? String) ?? "" }
    var newsAPIKey: String { (dict["NewsAPIKey"] as? String) ?? "" }
}
