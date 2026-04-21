import SwiftUI
import Combine

@MainActor
final class SkillBrowserViewModel: ObservableObject {
    @Published var skills: [Skill] = []
    @Published var isLoading = false

    private let firestore = FirestoreService.shared

    func load() async {
        isLoading = true
        skills = (try? await firestore.fetchAllSkills()) ?? []
        isLoading = false
    }
}
