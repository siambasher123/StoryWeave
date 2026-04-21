import SwiftUI

struct AmbientParticleView: View {
    @State private var particles: [Particle] = (0..<30).map { _ in Particle.random() }
    @State private var hasSlot = false

    var body: some View {
        Group {
            if hasSlot {
                TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                    Canvas { context, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        for particle in particles {
                            let elapsed = now - particle.birth
                            let lifetime = particle.lifetime
                            guard elapsed < lifetime else { continue }

                            let progress = elapsed / lifetime
                            let x = (particle.x * size.width + cos(now * particle.drift) * 20).truncatingRemainder(dividingBy: size.width)
                            let y = ((particle.y + progress * 0.3) * size.height).truncatingRemainder(dividingBy: size.height)
                            let alpha = sin(progress * .pi) * particle.opacity

                            context.opacity = alpha
                            context.fill(
                                Path(ellipseIn: CGRect(x: x, y: y, width: particle.size, height: particle.size)),
                                with: .color(particle.color)
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

private struct Particle: Sendable {
    let x: Double
    let y: Double
    let size: Double
    let opacity: Double
    let drift: Double
    let lifetime: Double
    let birth: Double
    let color: Color

    static func random() -> Particle {
        let colors: [Color] = [.swAccentPrimary, .swAccentHighlight, .swTextSecondary]
        return Particle(
            x: Double.random(in: 0...1),
            y: Double.random(in: 0...1),
            size: Double.random(in: 2...5),
            opacity: Double.random(in: 0.1...0.4),
            drift: Double.random(in: 0.1...0.5),
            lifetime: Double.random(in: 4...10),
            birth: Date.timeIntervalSinceReferenceDate - Double.random(in: 0...10),
            color: colors.randomElement()!
        )
    }
}
