import Combine
import Foundation

extension Notification.Name {
    /// Posted by AppSession.clear() so AppDelegate can reset the UIKit window.
    static let userDidLogout = Notification.Name("userDidLogout")
}

class AppSession: ObservableObject {
    /// Shared singleton used by the UIKit layer to inject into SwiftUI hosting controllers.
    static let shared = AppSession()

    @Published var userId: String?
    @Published var email: String = ""

    func set(userId: String, email: String) {
        self.userId = userId
        self.email = email
    }

    func clear() {
        self.userId = nil
        self.email = ""
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }
}
