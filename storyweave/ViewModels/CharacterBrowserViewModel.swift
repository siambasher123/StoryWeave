import SwiftUI
import Combine

@MainActor
final class CharacterBrowserViewModel: ObservableObject {
    @Published var characters: [Character] = []
    @Published var isLoading = false

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    var currentUserID: String? { auth.currentUserID }

    func load() async {
        isLoading = true
        let remote = (try? await firestore.fetchAllCharacters()) ?? []
        let systemIDs = Set(DefaultContent.defaultCharacters.map(\.id))
        let system = remote.filter { systemIDs.contains($0.id) }
        let userCreated = remote.filter { !systemIDs.contains($0.id) }
        let systemChars = system.isEmpty ? DefaultContent.defaultCharacters : system
        characters = systemChars + userCreated
        isLoading = false
    }

    func delete(_ character: Character) async {
        characters.removeAll { $0.id == character.id }
        try? await firestore.deleteCharacter(characterID: character.id)
    }

    func update(_ character: Character) {
        try? firestore.updateCharacter(character)
        if let idx = characters.firstIndex(where: { $0.id == character.id }) {
            characters[idx] = character
        }
    }
}
