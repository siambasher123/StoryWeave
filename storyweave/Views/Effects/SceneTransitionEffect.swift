import SwiftUI

struct SceneTransitionEffect: GeometryEffect {
    var offsetFraction: CGFloat

    var animatableData: CGFloat {
        get { offsetFraction }
        set { offsetFraction = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: size.width * offsetFraction, y: 0))
    }
}

extension AnyTransition {
    static let sceneWipe: AnyTransition = .asymmetric(
        insertion: .modifier(
            active: SceneTransitionEffect(offsetFraction: 1),
            identity: SceneTransitionEffect(offsetFraction: 0)
        ),
        removal: .modifier(
            active: SceneTransitionEffect(offsetFraction: -1),
            identity: SceneTransitionEffect(offsetFraction: 0)
        )
    )
}
