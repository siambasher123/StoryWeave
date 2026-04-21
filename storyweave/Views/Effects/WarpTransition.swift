import SwiftUI

struct WarpTransitionModifier: GeometryEffect {
    var progress: CGFloat   // 0 (hidden left) → 1 (on screen)

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let tx = size.width * (1 - progress)
        // Perspective warp — pinch the trailing edge as it slides in
        let skew: CGFloat = (1 - progress) * 0.15
        var t = CATransform3DIdentity
        t.m34 = -1.0 / 600          // perspective depth
        t = CATransform3DTranslate(t, tx, 0, 0)
        t.m14 = skew                // horizontal shear
        return ProjectionTransform(t)
    }
}

extension AnyTransition {
    static var warpWipe: AnyTransition {
        .modifier(
            active:   WarpTransitionModifier(progress: 0),
            identity: WarpTransitionModifier(progress: 1)
        )
    }
}
