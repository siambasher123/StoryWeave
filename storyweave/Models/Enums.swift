import Foundation

enum Archetype: String, Codable, CaseIterable, Sendable {
    case warrior, mage, rogue, cleric, ranger, tank
}

enum StatType: String, Codable, CaseIterable, Sendable {
    case hp, atk, def, dex, intel
}

enum TargetType: String, Codable, CaseIterable, Sendable {
    case `self`, ally, enemy, allEnemies
}

enum SceneType: String, Codable, CaseIterable, Sendable {
    case exploration, dialogue, combat, skillCheck
}

enum CombatOutcome: String, Codable, Sendable {
    case criticalFail, fail, partialSuccess, success, criticalSuccess

    static func from(roll: Int) -> CombatOutcome {
        switch roll {
        case ...2:   return .criticalFail
        case 3...7:  return .fail
        case 8...13: return .partialSuccess
        case 14...19: return .success
        default:     return .criticalSuccess
        }
    }
}

enum ItemType: String, Codable, CaseIterable, Sendable {
    case consumable, passive, keyItem
}
