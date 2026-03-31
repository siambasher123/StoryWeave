import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                StoryLibraryView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Library", systemImage: "books.vertical.fill")
            }

            NavigationView {
                AnalyticsView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.fill")
            }

            NavigationView {
                ProfileView()
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
        }
        .accentColor(.indigo)
    }
}
