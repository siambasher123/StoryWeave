import Foundation

enum SessionStatus: String, Codable, Sendable { case lobby, playing, completed, abandoned }
enum SessionPlayerStatus: String, Codable, Sendable { case invited, joined, ready }
enum SessionStoryType: String, Codable, Sendable { case campaign, userStory }

struct SessionPlayer: Codable, Identifiable, Sendable {
    let id: String          // UID
    var displayName: String
    var characterID: String
    var status: SessionPlayerStatus
    var isReady: Bool
    var turnIndex: Int
}

struct CombatSnapshot: Codable, Sendable {
    var enemies: [EnemyCombatantCodable]
    var phase: String       // "playerTurn" | "botTurn" | "enemyTurn" | "complete"
    var currentCombatantUID: String?
    var taunted: String?
    var lastRoll: Int?
    var lastOutcome: String?
}

struct EnemyCombatantCodable: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var emoji: String
    var hp: Int
    let maxHP: Int
    let atk: Int
    let def: Int
    let dex: Int
}

struct GameSession: Codable, Identifiable, Sendable {
    let id: String
    var hostUID: String
    var storyType: SessionStoryType
    var storyID: String?
    var status: SessionStatus
    var invitedUIDs: [String]
    var players: [SessionPlayer]
    var botCharacterIDs: [String]
    var gameState: GameState
    var currentNarration: String
    var currentTurnUID: String?
    var currentTurnIndex: Int
    var combatSnapshot: CombatSnapshot?
    var pendingActionJSON: String?
    var createdAt: Date

    static func new(hostUID: String, hostName: String, storyType: SessionStoryType = .campaign) -> GameSession {
        GameSession(
            id: UUID().uuidString,
            hostUID: hostUID,
            storyType: storyType,
            storyID: nil,
            status: .lobby,
            invitedUIDs: [hostUID],
            players: [SessionPlayer(
                id: hostUID, displayName: hostName,
                characterID: "", status: .joined, isReady: false, turnIndex: 0
            )],
            botCharacterIDs: [],
            gameState: GameState.newGame(playerCharacterID: "", botCharacterIDs: []),
            currentNarration: "",
            currentTurnUID: hostUID,
            currentTurnIndex: 0,
            combatSnapshot: nil,
            pendingActionJSON: nil,
            createdAt: Date()
        )
    }
}
