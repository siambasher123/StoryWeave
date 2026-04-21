import SwiftUI

struct ProjectileView: View {
    let emoji: String
    let fromX: CGFloat
    let fromY: CGFloat
    let toX: CGFloat
    let toY: CGFloat
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0

    private var currentX: CGFloat { fromX + (toX - fromX) * progress }
    private var currentY: CGFloat { fromY + (toY - fromY) * progress }

    var body: some View {
        Text(emoji)
            .font(.system(size: 24))
            .position(x: currentX, y: currentY)
            .onAppear {
                withAnimation(.linear(duration: 0.4)) {
                    progress = 1
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(420))
                    onComplete()
                }
            }
    }
}
