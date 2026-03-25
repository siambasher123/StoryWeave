import SwiftUI

struct AuthGateView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        if session.userId != nil {
            MainTabView()
        } else {
            LoginView()
        }
    }
}
