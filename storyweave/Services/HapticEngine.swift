import UIKit

/// Haptic feedback engine for tactile user experience enhancement
/// Provides physical vibration patterns in response to game events, UI actions, and combat
/// Uses iOS's built-in haptic feedback generators for efficient battery usage
enum HapticEngine {
    /// Types of haptic feedback available for different game events
    enum FeedbackType {
        /// Success feedback - gentle tap indicating positive outcome
        /// Used for: leveling up, successful skill checks, completed quests
        case success
        
        /// Warning feedback - medium vibration alerting to important info
        /// Used for: low health, approaching danger, quest markers
        case warning
        
        /// Error feedback - strong vibration indicating failure/damage
        /// Used for: combat hits, spell failures, character defeat
        case error
        
        /// Impact feedback - customizable intensity vibration
        /// Styles: light, medium, heavy
        /// Used for: combat actions, attacks, environmental impact
        case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    }

    /// Plays haptic feedback for a given feedback type
    /// Adapts intensity and pattern based on feedback type for intuitive physical response
    /// Safe to call on any device - gracefully degrades on devices without haptic support
    /// 
    /// - Parameter type: The FeedbackType determining vibration pattern
    static func play(_ type: FeedbackType) {
        switch type {
        case .success:
            // Three quick taps - indicates successful action completion
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            // Two warning-style vibrations - alerts player to caution
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            // Strong single vibration - signals failure or damage
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .impact(let style):
            // Customizable impact vibration - style determines intensity
            // light: quick tap (UI interactions)
            // medium: standard impact (combat actions)
            // heavy: strong impact (critical hits, explosions)
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }
}
