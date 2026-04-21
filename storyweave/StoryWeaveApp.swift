import SwiftUI
import FirebaseCore

@main
struct StoryWeaveApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showSplash = true

    init() {
        FirebaseApp.configure()
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ZStack {
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

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                        .task {
                            try? await Task.sleep(for: .seconds(1.9))
                            withAnimation(.easeOut(duration: 0.45)) {
                                showSplash = false
                            }
                        }
                }
            }
        }
    }
}
