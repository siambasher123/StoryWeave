import UIKit

/// UIKit entry view controller. Reads the persisted Firebase auth state on launch
/// and replaces itself in the navigation stack with either LoginViewController
/// (unauthenticated) or MainHostViewController (authenticated) without any visible flash.
class AuthGateViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        routeFromCurrentAuthState()
    }

    private func routeFromCurrentAuthState() {
        if let user = AuthService.shared.currentUser {
            // Restore the shared session from Firebase's persisted credential
            AppSession.shared.set(userId: user.userId, email: user.email)
            navigationController?.setViewControllers([MainHostViewController()], animated: false)
        } else {
            navigationController?.setViewControllers([LoginViewController()], animated: false)
        }
    }
}
