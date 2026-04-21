import Foundation

struct GameAnalytics: Codable, Sendable {
    var totalPlaytimeSeconds: Int
    var actsCompleted: Int
    var combatsWon: Int
    var combatsLost: Int
    var charactersLost: Int
    var skillChecksAttempted: Int
    var skillChecksPassed: Int

    static let empty = GameAnalytics(
        totalPlaytimeSeconds: 0,
        actsCompleted: 0,
        combatsWon: 0,
        combatsLost: 0,
        charactersLost: 0,
        skillChecksAttempted: 0,
        skillChecksPassed: 0
    )
}
