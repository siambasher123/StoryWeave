import SwiftUI
import FirebaseCore

@main
struct StoryWeaveApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        FirebaseApp.configure()
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            Group {
                if authViewModel.isSignedIn {
                    MainTabView()
                        .task { await FirestoreService.shared.ensureDefaultsSeeded() }
                } else {
                    AuthView()
                }
            }
            .preferredColorScheme(.dark)
            .environmentObject(authViewModel)
        }
    }
}
