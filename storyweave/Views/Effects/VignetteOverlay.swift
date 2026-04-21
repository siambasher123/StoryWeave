import SwiftUI

struct VignetteOverlay: View {
    let partyHPPercent: Double
    @State private var pulseOpacity: Double = 0

    var body: some View {
        RadialGradient(
            colors: [.clear, .black.opacity(0.7)],
            center: .center,
            startRadius: 120,
            endRadius: 340
        )
        .opacity(pulseOpacity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: partyHPPercent, initial: true) { _, pct in
            if pct < 0.30 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseOpacity = 1
                }
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    pulseOpacity = 0
                }
            }
        }
    }
}
