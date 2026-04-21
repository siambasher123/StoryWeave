import Foundation

struct CombatEngine {
    static func rollD20() -> Int { Int.random(in: 1...20) }

    static func resolveAttack(attacker: Character, target: Character) -> (outcome: CombatOutcome, damage: Int) {
        let roll = rollD20()
        let modified = roll + attacker.atk - target.def
        let outcome = CombatOutcome.from(roll: modified)
        let damage: Int
        switch outcome {
        case .criticalFail:    damage = 0
        case .fail:            damage = 0
        case .partialSuccess:  damage = max(1, attacker.atk / 2)
        case .success:         damage = attacker.atk
        case .criticalSuccess: damage = attacker.atk * 2
        }
        return (outcome, damage)
    }

    static func resolveEnemyAttack(enemy: Enemy, target: Character) -> (outcome: CombatOutcome, damage: Int) {
        let roll = rollD20()
        let modified = roll + enemy.atk - target.def
        let outcome = CombatOutcome.from(roll: modified)
        let damage: Int
        switch outcome {
        case .criticalFail:    damage = 0
        case .fail:            damage = 0
        case .partialSuccess:  damage = max(1, enemy.atk / 2)
        case .success:         damage = enemy.atk
        case .criticalSuccess: damage = enemy.atk * 2
        }
        return (outcome, damage)
    }

    static func resolveSkillCheck(character: Character, stat: StatType, difficulty: Int) -> (outcome: CombatOutcome, roll: Int) {
        let roll = rollD20()
        let modifier: Int
        switch stat {
        case .atk:   modifier = character.atk
        case .def:   modifier = character.def
        case .dex:   modifier = character.dex
        case .intel: modifier = character.intel
        case .hp:    modifier = 0
        }
        let modified = roll + modifier - difficulty
        return (CombatOutcome.from(roll: modified), roll)
    }

    static func resolveBotTurn(bot: Character, party: [Character], enemies: [EnemyCombatant]) -> BotAction {
        let aliveEnemies = enemies.filter { $0.hp > 0 }
        guard !aliveEnemies.isEmpty else { return .defend }

        switch bot.archetype {
        case .cleric:
            if let wounded = party.first(where: { $0.hp > 0 && $0.hp < $0.maxHP / 2 }) {
                return .heal(targetID: wounded.id, amount: max(5, bot.intel / 2 + 8))
            }
            if let weakest = aliveEnemies.min(by: { $0.hp < $1.hp }) {
                return .attackEnemy(targetID: weakest.id, damage: max(1, bot.atk - weakest.def))
            }

        case .warrior:
            if let target = aliveEnemies.max(by: { $0.hp < $1.hp }) {
                return .attackEnemy(targetID: target.id, damage: max(1, bot.atk - target.def + rollD20() / 4))
            }

        case .tank:
            // Tank taunts (acts as if defending, but absorbs next hit for one party member)
            if let weakest = party.filter({ $0.hp > 0 }).min(by: { $0.hp < $1.hp }),
               weakest.id != bot.id {
                return .taunt(protectID: weakest.id)
            }
            if let target = aliveEnemies.max(by: { $0.hp < $1.hp }) {
                return .attackEnemy(targetID: target.id, damage: max(1, bot.atk - target.def))
            }

        case .mage:
            // Mage hits the weakest enemy cluster — for simplicity, attacks weakest
            if let weakest = aliveEnemies.min(by: { $0.hp < $1.hp }) {
                return .attackEnemy(targetID: weakest.id, damage: max(2, bot.intel / 2 + rollD20() / 5))
            }

        case .rogue:
            // Rogue targets the most defensively vulnerable (lowest def)
            if let softest = aliveEnemies.min(by: { $0.def < $1.def }) {
                return .attackEnemy(targetID: softest.id, damage: max(1, bot.dex / 2 + bot.atk / 2))
            }

        case .ranger:
            if let weakest = aliveEnemies.min(by: { $0.hp < $1.hp }) {
                return .attackEnemy(targetID: weakest.id, damage: max(1, bot.dex / 3 + bot.atk))
            }
        }
        return .defend
    }
}

// A live enemy combatant in combat (derived from Enemy template + current HP)
struct EnemyCombatant: Identifiable, Sendable {
    let id: String
    let name: String
    let emoji: String
    var hp: Int
    let maxHP: Int
    let atk: Int
    let def: Int
    let dex: Int

    init(from enemy: Enemy) {
        id    = enemy.id + "_" + UUID().uuidString.prefix(4)
        name  = enemy.name
        emoji = enemy.emoji
        hp    = enemy.hp
        maxHP = enemy.maxHP
        atk   = enemy.atk
        def   = enemy.def
        dex   = enemy.dex
    }
}

enum BotAction: Sendable {
    case attackEnemy(targetID: String, damage: Int)
    case heal(targetID: String, amount: Int)
    case taunt(protectID: String)
    case defend
}
