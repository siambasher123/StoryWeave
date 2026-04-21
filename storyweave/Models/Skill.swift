import Foundation

struct Skill: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var description: String
    var statAffected: StatType
    var modifier: Int
    var cooldownTurns: Int
    var targetType: TargetType
    var createdByUID: String
}
