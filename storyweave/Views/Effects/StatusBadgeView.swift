import SwiftUI

enum StatusEffect: String, Sendable {
    case protected = "🛡"
    case poisoned  = "☠️"
    case blessed   = "✨"
    case stunned   = "💫"
    case burning   = "🔥"
}

struct StatusBadgeView: View {
    let status: StatusEffect
    @State private var scale: CGFloat = 1

    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 14))
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    scale = 1.2
                }
            }
    }
}
