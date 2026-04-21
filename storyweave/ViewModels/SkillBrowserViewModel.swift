import SwiftUI
import Combine

@MainActor
final class SkillBrowserViewModel: ObservableObject {
    @Published var skills: [Skill] = []
    @Published var isLoading = false

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    var currentUserID: String? { auth.currentUserID }

    func load() async {
        isLoading = true
        skills = (try? await firestore.fetchAllSkills()) ?? []
        isLoading = false
    }

    func delete(_ skill: Skill) async {
        skills.removeAll { $0.id == skill.id }
        try? await firestore.deleteSkill(skillID: skill.id)
    }

    func update(_ skill: Skill) {
        try? firestore.updateSkill(skill)
        if let idx = skills.firstIndex(where: { $0.id == skill.id }) {
            skills[idx] = skill
        }
    }
}
