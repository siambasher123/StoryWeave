import SwiftUI
import CoreMotion

struct ExplorationParallaxView<Content: View>: View {
    let content: () -> Content
    @State private var xOffset: CGFloat = 0
    @State private var yOffset: CGFloat = 0
    @State private var motionManager = CMMotionManager()

    var body: some View {
        content()
            .offset(x: xOffset, y: yOffset)
            .onAppear { startMotion() }
            .onDisappear { motionManager.stopDeviceMotionUpdates() }
    }

    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30
        motionManager.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let data else { return }
            let clamp: (Double) -> CGFloat = { CGFloat(max(-12, min(12, $0 * 30))) }
            xOffset = clamp(data.gravity.x)
            yOffset = clamp(-data.gravity.y)
        }
    }
}
