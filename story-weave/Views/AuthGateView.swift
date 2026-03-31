import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject var session: AppSession
    @State private var isResolving = true

    var body: some View {
        Group {
            if isResolving {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if session.userId != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            if let user = AuthService.shared.currentUser {
                session.set(userId: user.userId, email: user.email)
            }
            isResolving = false
        }
    }
}
