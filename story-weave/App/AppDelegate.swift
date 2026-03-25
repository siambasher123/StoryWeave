import FirebaseCore
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
	) -> Bool {
		FirebaseApp.configure()

		window = UIWindow(frame: UIScreen.main.bounds)
		let nav = UINavigationController(rootViewController: AuthGateViewController())
		nav.setNavigationBarHidden(true, animated: false)
		window?.rootViewController = nav
		window?.makeKeyAndVisible()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleLogout),
			name: .userDidLogout,
			object: nil
		)

		return true
	}

	@objc private func handleLogout() {
		let nav = UINavigationController(rootViewController: LoginViewController())
		nav.setNavigationBarHidden(true, animated: false)
		guard let window else { return }
		UIView.transition(
			with: window,
			duration: 0.3,
			options: .transitionCrossDissolve
		) {
			self.window?.rootViewController = nav
		}
	}
}
