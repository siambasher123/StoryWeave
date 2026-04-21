import SwiftUI
import Combine

@MainActor
final class CreateSkillViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var statAffected: StatType = .atk
    @Published var targetType: TargetType = .enemy
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didCreate = false

    @Clamped(1...50) var modifier: Int = 10
    @Clamped(0...5) var cooldownTurns: Int = 2

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    func create() async {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Name is required."
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let uid = auth.currentUserID else { return }

        let skill = Skill(
            id: UUID().uuidString,
            name: name,
            description: description,
            statAffected: statAffected,
            modifier: modifier,
            cooldownTurns: cooldownTurns,
            targetType: targetType,
            createdByUID: uid
        )
        do {
            try firestore.createSkill(skill)
            didCreate = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
