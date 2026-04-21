import SwiftUI

struct FloatingDamageNumber: View {
    let text: String
    let color: Color
    let onComplete: () -> Void

    @State private var yOffset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.6), radius: 4)
            .offset(y: yOffset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    yOffset = -60
                    opacity = 0
                }
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    onComplete()
                }
            }
    }
}
