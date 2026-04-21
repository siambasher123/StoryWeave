import UIKit

enum HapticEngine {
    enum FeedbackType {
        case success
        case warning
        case error
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    }

    static func play(_ type: FeedbackType) {
        switch type {
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .impact(let style):
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}
