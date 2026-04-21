import SwiftUI

struct HealingParticlesView: View {
    @State private var hasSlot = false
    @State private var particles: [HealParticle] = (0..<25).map { _ in HealParticle() }

    var body: some View {
        Group {
            if hasSlot {
                TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        for p in particles {
                            let elapsed = now - p.birth
                            guard elapsed < p.lifetime else { continue }
                            let prog = elapsed / p.lifetime
                            let x = p.startX * size.width + cos(now * p.drift) * 8
                            let y = p.startY * size.height - prog * p.riseSpeed
                            let alpha = sin(prog * .pi) * 0.7
                            context.opacity = alpha
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: p.size, height: p.size)),
                                with: .color(prog < 0.5 ? Color.swSuccess : .white)
                            )
                        }
                    }
                    .drawingGroup()
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            hasSlot = AnimationCoordinator.shared.requestSlot()
        }
        .onDisappear {
            if hasSlot { AnimationCoordinator.shared.releaseSlot() }
        }
    }
}

private struct HealParticle {
    let startX: Double
    let startY: Double
    let size: Double
    let drift: Double
    let riseSpeed: Double
    let lifetime: Double
    let birth: Double

    init() {
        startX = Double.random(in: 0.2...0.8)
        startY = Double.random(in: 0.4...0.9)
        size = Double.random(in: 3...7)
        drift = Double.random(in: 0.2...0.8)
        riseSpeed = Double.random(in: 40...80)
        lifetime = Double.random(in: 1...2.5)
        birth = Date.timeIntervalSinceReferenceDate - Double.random(in: 0...2)
    }
}
