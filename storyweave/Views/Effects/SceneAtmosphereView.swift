import SwiftUI

enum AtmosphereType: Sendable {
    case embers, snow, sparkles, rain
}

struct SceneAtmosphereView: View {
    let type: AtmosphereType
    @State private var hasSlot = false
    @State private var particles: [AtmosphereParticle] = []

    var body: some View {
        Group {
            if hasSlot {
                TimelineView(.animation(minimumInterval: 1.0 / 60)) { timeline in
                    Canvas { ctx, size in
                        let now = timeline.date.timeIntervalSinceReferenceDate
                        for p in particles {
                            let elapsed = now - p.birth
                            guard elapsed < p.lifetime else { continue }
                            let prog = elapsed / p.lifetime
                            let (x, y, alpha) = position(p: p, progress: prog, elapsed: elapsed, size: size)
                            ctx.opacity = alpha
                            let rect = CGRect(x: x, y: y, width: p.size, height: p.height)
                            ctx.fill(Path(ellipseIn: rect), with: .color(p.color))
                        }
                    }
                    .drawingGroup()
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            particles = makeParticles()
            hasSlot = AnimationCoordinator.shared.requestSlot()
        }
        .onDisappear {
            if hasSlot { AnimationCoordinator.shared.releaseSlot() }
        }
    }

    private func position(p: AtmosphereParticle, progress: Double, elapsed: Double, size: CGSize) -> (CGFloat, CGFloat, CGFloat) {
        let alpha = sin(progress * .pi) * 0.65
        switch type {
        case .embers:
            let x = (p.startX * size.width + cos(elapsed * p.drift) * 12).truncatingRemainder(dividingBy: size.width)
            let y = ((p.startY - progress * 0.4) * size.height).truncatingRemainder(dividingBy: size.height)
            return (x, y, alpha)
        case .snow:
            let x = (p.startX * size.width + sin(elapsed * p.drift) * 6).truncatingRemainder(dividingBy: size.width)
            let y = (progress * size.height * 1.1)
            return (x, y, alpha)
        case .sparkles:
            let x = (p.startX * size.width + cos(elapsed * p.drift * 2) * 15).truncatingRemainder(dividingBy: size.width)
            let y = (p.startY * size.height + sin(elapsed * p.drift) * 15).truncatingRemainder(dividingBy: size.height)
            return (x, y, alpha)
        case .rain:
            let x = p.startX * size.width + elapsed * 20
            let y = progress * size.height * 1.3
            return (x, y, min(alpha, 0.4))
        }
    }

    private func makeParticles() -> [AtmosphereParticle] {
        let count: Int
        switch type {
        case .embers: count = 25
        case .snow: count = 30
        case .sparkles: count = 20
        case .rain: count = 35
        }
        return (0..<count).map { _ in AtmosphereParticle(type: type) }
    }
}

private struct AtmosphereParticle {
    let startX: Double
    let startY: Double
    let size: Double
    let height: Double
    let drift: Double
    let lifetime: Double
    let birth: Double
    let color: Color

    init(type: AtmosphereType) {
        startX = Double.random(in: 0...1)
        startY = Double.random(in: 0...1)
        drift  = Double.random(in: 0.2...0.8)
        birth  = Date.timeIntervalSinceReferenceDate - Double.random(in: 0...5)
        switch type {
        case .embers:
            size = Double.random(in: 2...5); height = size
            lifetime = Double.random(in: 3...7)
            color = [Color.orange, Color.red, Color(hex: "#FF6B35")].randomElement()!
        case .snow:
            size = Double.random(in: 3...7); height = size
            lifetime = Double.random(in: 4...8)
            color = Color.white.opacity(Double.random(in: 0.5...0.9))
        case .sparkles:
            size = Double.random(in: 2...4); height = size
            lifetime = Double.random(in: 1.5...4)
            color = [Color.swAccentLight, Color.swAccentPrimary, Color.white].randomElement()!
        case .rain:
            size = Double.random(in: 1...2); height = Double.random(in: 10...20)
            lifetime = Double.random(in: 1...2.5)
            color = Color.swAccentLight.opacity(0.4)
        }
    }
}
