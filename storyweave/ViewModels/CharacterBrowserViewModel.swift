import SwiftUI
import Combine

@MainActor
final class CharacterBrowserViewModel: ObservableObject {
    @Published var characters: [Character] = []
    @Published var isLoading = false

    private let firestore = FirestoreService.shared

    func load() async {
        isLoading = true
        let remote = (try? await firestore.fetchAllCharacters()) ?? []
        // System defaults first, then user-created
        let systemIDs = Set(DefaultContent.defaultCharacters.map(\.id))
        let system = remote.filter { systemIDs.contains($0.id) }
        let userCreated = remote.filter { !systemIDs.contains($0.id) }
        // Fallback: if remote has no system chars yet (pre-seed), show local defaults
        let systemChars = system.isEmpty ? DefaultContent.defaultCharacters : system
        characters = systemChars + userCreated
        isLoading = false
    }
}
