import SwiftUI
import UIKit

/// Bridges the UIKit navigation stack to the SwiftUI world.
/// All SwiftUI views downstream receive AppSession.shared via the environment.
class MainHostViewController: UIHostingController<AnyView> {

    init() {
        let rootView = AnyView(
            MainTabView()
                .environmentObject(AppSession.shared)
        )
        super.init(rootView: rootView)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("Use init() instead.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Hide the UINavigationController bar — MainTabView manages its own navigation
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
