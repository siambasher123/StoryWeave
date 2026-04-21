import SwiftUI
import Combine

@MainActor
final class InventoryViewModel: ObservableObject {
    @Published var inventory: [InventoryItem] = []
    @Published var unlockedAchievements: [Achievement] = []

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    func load() async {
        guard let uid = auth.currentUserID else { return }

        if let state = try? await firestore.loadGameState(uid: uid) {
            inventory = state.inventory.isEmpty ? DefaultContent.defaultInventory : state.inventory
        } else {
            inventory = DefaultContent.defaultInventory
        }

        if let profile = try? await firestore.fetchUserProfile(uid: uid) {
            unlockedAchievements = Achievement.allCases.filter { $0.isUnlocked(profile.gameStats) }
        }
    }
}

struct Achievement: Identifiable, CaseIterable, Sendable {
    let id: String
    let title: String
    let description: String
    let isUnlocked: @Sendable (GameAnalytics) -> Bool

    static let allCases: [Achievement] = [
        Achievement(id: "first_combat",  title: "First Blood",           description: "Win your first combat",                      isUnlocked: { $0.combatsWon >= 1 }),
        Achievement(id: "act1",          title: "Into the Dark",         description: "Complete Act 1",                             isUnlocked: { $0.actsCompleted >= 1 }),
        Achievement(id: "act5",          title: "Echoes of the Fallen",  description: "Complete the full campaign",                 isUnlocked: { $0.actsCompleted >= 5 }),
        Achievement(id: "no_deaths",     title: "Unbroken",              description: "Complete a run with no character deaths",    isUnlocked: { $0.charactersLost == 0 && $0.actsCompleted >= 5 }),
        Achievement(id: "skill_master",  title: "Skill Master",          description: "Attempt 10 skill checks",                   isUnlocked: { $0.skillChecksAttempted >= 10 }),
        Achievement(id: "survivor",      title: "Against All Odds",      description: "Complete a run with only 1 party member left", isUnlocked: { $0.charactersLost >= 4 && $0.actsCompleted >= 5 }),
        Achievement(id: "tactician",     title: "Tactician",             description: "Win 5 combats",                             isUnlocked: { $0.combatsWon >= 5 })
    ]
}
