import Foundation

struct GameState: Codable, Sendable {
    var currentActIndex: Int
    var currentSceneID: String
    var partyCharacterIDs: [String]
    var playerCharacterID: String
    var botCharacterIDs: [String]
    var decisionHistory: [String: String]
    var survivingCharacterIDs: [String]
    var inventory: [InventoryItem]
    var playerXP: Int
    var playerLevel: Int
    var customStartSceneID: String?     // non-nil for user stories; nil = campaign default

    static func newGame(playerCharacterID: String, botCharacterIDs: [String]) -> GameState {
        newGame(playerCharacterID: playerCharacterID, botCharacterIDs: botCharacterIDs, startSceneID: "act1_scene1")
    }

    static func newGame(playerCharacterID: String, botCharacterIDs: [String], startSceneID: String) -> GameState {
        let allIDs = [playerCharacterID] + botCharacterIDs
        return GameState(
            currentActIndex: 0,
            currentSceneID: startSceneID,
            partyCharacterIDs: allIDs,
            playerCharacterID: playerCharacterID,
            botCharacterIDs: botCharacterIDs,
            decisionHistory: [:],
            survivingCharacterIDs: allIDs,
            inventory: DefaultContent.defaultInventory,
            playerXP: 0,
            playerLevel: 1,
            customStartSceneID: startSceneID == "act1_scene1" ? nil : startSceneID
        )
    }
}
