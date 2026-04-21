import SwiftUI
import UIKit

struct MainTabView: View {
    @State private var selectedTab = 0

    init() {
        let a = UITabBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor = UIColor(red: 0.094, green: 0.086, blue: 0.188, alpha: 1.0) // #181630

        let normal = a.stackedLayoutAppearance.normal
        let selected = a.stackedLayoutAppearance.selected

        normal.iconColor = UIColor(Color.swTextSecondary)
        normal.titleTextAttributes = [.foregroundColor: UIColor(Color.swTextSecondary)]

        selected.iconColor = UIColor(Color.swAccentLight)
        selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.swAccentLight),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        UITabBar.appearance().standardAppearance = a
        UITabBar.appearance().scrollEdgeAppearance = a
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                GameView()
            }
            .tabItem { Label("Play", systemImage: "dice.fill") }
            .tag(1)

            NavigationStack {
                CreateTabView()
            }
            .tabItem { Label("Create", systemImage: "plus.circle.fill") }
            .tag(2)

            NavigationStack {
                LibraryView()
            }
            .tabItem { Label("Library", systemImage: "books.vertical.fill") }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(4)
        }
        .tint(Color.swAccentLight)
    }
}
