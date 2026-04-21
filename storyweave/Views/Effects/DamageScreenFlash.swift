import SwiftUI

struct DamageScreenFlash: View {
    @Binding var isShowing: Bool
    @State private var opacity: Double = 0

    var body: some View {
        Color.swDanger
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onChange(of: isShowing) { _, showing in
                guard showing else { return }
                opacity = 0.35
                withAnimation(.easeOut(duration: 0.4)) {
                    opacity = 0
                }
                Task {
                    try? await Task.sleep(for: .milliseconds(450))
                    isShowing = false
                }
            }
    }
}
