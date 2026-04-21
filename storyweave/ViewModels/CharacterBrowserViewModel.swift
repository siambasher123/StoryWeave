import SwiftUI
import Combine

/// ViewModel for displaying and managing the character selection/browse interface
/// Loads game characters from Firestore and organizes them by type (system vs user-created)
/// Provides reactive state for UI binding and loading indicators
@MainActor
final class CharacterBrowserViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of all available characters to display in the browser
    /// Organized as: system default characters first, then user-created characters
    @Published var characters: [Character] = []
    
    /// Loading state while fetching characters from Firestore
    /// true during fetch, false when complete
    @Published var isLoading = false

    // MARK: - Dependencies
    
    /// Shared Firestore service for character data retrieval
    private let firestore = FirestoreService.shared

    // MARK: - Methods
    
    /// Loads all characters from Firestore and organizes them by source type
    /// 
    /// Process:
    /// 1. Fetches all characters from Firestore database
    /// 2. Separates system default characters from user-created characters
    /// 3. If Firestore has system chars, uses those; otherwise falls back to local defaults
    /// 4. Combines sorted list: system defaults first, then user-created
    /// 5. Updates published characters property for UI binding
    /// 
    /// This organization ensures players always see built-in characters first,
    /// followed by any custom characters the community has created
    func load() async {
        isLoading = true
        
        // Fetch all characters from Firestore (includes both system and user-created)
        let remote = (try? await firestore.fetchAllCharacters()) ?? []
        
        // Separate system default characters from user-created ones
        let systemIDs = Set(DefaultContent.defaultCharacters.map(\.id))
        let system = remote.filter { systemIDs.contains($0.id) }
        let userCreated = remote.filter { !systemIDs.contains($0.id) }
        
        // Fallback: if Firestore doesn't have system chars yet (pre-seed),
        // use local default characters to ensure players always have options
        let systemChars = system.isEmpty ? DefaultContent.defaultCharacters : system
        
        // Combine lists: system defaults first, then user-created for better UX
        characters = systemChars + userCreated
        isLoading = false
    }
}
