import SwiftUI

struct CriticalHitParticleView: View {
    @State private var particles: [GoldParticle] = (0..<40).map { _ in GoldParticle() }
    @State private var hasSlot = false

    var body: some View {
        Group {
            if hasSlot {
                TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)

                        for particle in particles {
                            let elapsed = now - particle.birth
                            guard elapsed < particle.lifetime else { continue }
                            let progress = elapsed / particle.lifetime

                            let x = center.x + particle.velocityX * elapsed * 60
                            let y = center.y + particle.velocityY * elapsed * 60 + 0.5 * 200 * elapsed * elapsed
                            let alpha = 1 - progress
                            let sz = particle.size * (1 - progress * 0.5)

                            context.opacity = alpha
                            context.fill(
                                Path(ellipseIn: CGRect(x: x - sz/2, y: y - sz/2, width: sz, height: sz)),
                                with: .color(Color.swWarning)
                            )
                        }
                    }
                    .drawingGroup()
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { hasSlot = AnimationCoordinator.shared.requestSlot() }
        .onDisappear { if hasSlot { AnimationCoordinator.shared.releaseSlot() } }
    }
}

private struct GoldParticle {
    let velocityX: Double
    let velocityY: Double
    let size: Double
    let lifetime: Double
    let birth: Double

    init() {
        let angle = Double.random(in: 0...(2 * .pi))
        let speed = Double.random(in: 2...6)
        velocityX = cos(angle) * speed
        velocityY = sin(angle) * speed - 4
        size = Double.random(in: 4...10)
        lifetime = Double.random(in: 0.5...1.5)
        birth = Date.timeIntervalSinceReferenceDate
    }
}
