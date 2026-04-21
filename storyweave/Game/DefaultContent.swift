import Foundation

struct DefaultContent {

    // MARK: — Default Characters (6 system archetypes)

    static let defaultCharacters: [Character] = [
        Character(
            id: "sys_warrior_aric",
            name: "Aric Ironfist",
            archetype: .warrior,
            hp: 80, maxHP: 80,
            atk: 14, def: 10, dex: 6, intel: 4,
            skills: ["sys_skill_power_strike", "sys_skill_battle_cry"],
            createdByUID: "system",
            loreDescription: "A battle-scarred veteran who has fought in a dozen wars. His strength is unmatched, though wisdom sometimes eludes him.",
            level: 1, xp: 0
        ),
        Character(
            id: "sys_mage_lyra",
            name: "Lyra Moonveil",
            archetype: .mage,
            hp: 40, maxHP: 40,
            atk: 18, def: 3, dex: 8, intel: 18,
            skills: ["sys_skill_arcane_bolt", "sys_skill_mystic_shield"],
            createdByUID: "system",
            loreDescription: "A prodigy of the arcane arts who left the academy under mysterious circumstances. Her spells can turn the tide of any battle.",
            level: 1, xp: 0
        ),
        Character(
            id: "sys_rogue_finn",
            name: "Finn Darkwhisper",
            archetype: .rogue,
            hp: 55, maxHP: 55,
            atk: 12, def: 5, dex: 18, intel: 10,
            skills: ["sys_skill_shadow_strike", "sys_skill_evasion"],
            createdByUID: "system",
            loreDescription: "A former thief's guild member who now uses his skills for a higher purpose — or at least a more profitable one.",
            level: 1, xp: 0
        ),
        Character(
            id: "sys_cleric_sera",
            name: "Sera Dawnbringer",
            archetype: .cleric,
            hp: 60, maxHP: 60,
            atk: 8, def: 8, dex: 6, intel: 14,
            skills: ["sys_skill_divine_heal", "sys_skill_holy_light"],
            createdByUID: "system",
            loreDescription: "A devoted healer whose faith in the light is unshakeable. She has nursed entire companies back from the brink of death.",
            level: 1, xp: 0
        ),
        Character(
            id: "sys_ranger_dain",
            name: "Dain Swiftarrow",
            archetype: .ranger,
            hp: 65, maxHP: 65,
            atk: 13, def: 6, dex: 14, intel: 8,
            skills: ["sys_skill_aimed_shot", "sys_skill_hunters_mark"],
            createdByUID: "system",
            loreDescription: "A ranger from the northern wilds who can track prey across any terrain. His arrows rarely miss their mark.",
            level: 1, xp: 0
        ),
        Character(
            id: "sys_tank_kael",
            name: "Kael Stoneguard",
            archetype: .tank,
            hp: 100, maxHP: 100,
            atk: 8, def: 18, dex: 4, intel: 6,
            skills: ["sys_skill_shield_wall", "sys_skill_taunt"],
            createdByUID: "system",
            loreDescription: "A living fortress who has never taken a step back in battle. Enemies learn quickly that attacking Kael is a terrible idea.",
            level: 1, xp: 0
        )
    ]

    // MARK: — Default Skills (2 per archetype)

    static let defaultSkills: [Skill] = [
        Skill(id: "sys_skill_power_strike", name: "Power Strike",
              description: "A devastating blow that deals double ATK damage.",
              statAffected: .atk, modifier: 8, cooldownTurns: 2,
              targetType: .enemy, createdByUID: "system"),
        Skill(id: "sys_skill_battle_cry", name: "Battle Cry",
              description: "Inspires the party, raising their ATK for this turn.",
              statAffected: .atk, modifier: 4, cooldownTurns: 3,
              targetType: .ally, createdByUID: "system"),
        Skill(id: "sys_skill_arcane_bolt", name: "Arcane Bolt",
              description: "A concentrated beam of magical energy that ignores DEF.",
              statAffected: .atk, modifier: 10, cooldownTurns: 2,
              targetType: .enemy, createdByUID: "system"),
        Skill(id: "sys_skill_mystic_shield", name: "Mystic Shield",
              description: "Creates a magical barrier that absorbs damage.",
              statAffected: .def, modifier: 8, cooldownTurns: 3,
              targetType: .self, createdByUID: "system"),
        Skill(id: "sys_skill_shadow_strike", name: "Shadow Strike",
              description: "An attack from the shadows with a high critical chance.",
              statAffected: .dex, modifier: 6, cooldownTurns: 2,
              targetType: .enemy, createdByUID: "system"),
        Skill(id: "sys_skill_evasion", name: "Evasion",
              description: "Dramatically increases dodge chance for one turn.",
              statAffected: .dex, modifier: 8, cooldownTurns: 3,
              targetType: .self, createdByUID: "system"),
        Skill(id: "sys_skill_divine_heal", name: "Divine Heal",
              description: "Channels holy energy to restore 20 HP to an ally.",
              statAffected: .hp, modifier: 20, cooldownTurns: 2,
              targetType: .ally, createdByUID: "system"),
        Skill(id: "sys_skill_holy_light", name: "Holy Light",
              description: "A burst of sacred light that damages all enemies.",
              statAffected: .intel, modifier: 6, cooldownTurns: 3,
              targetType: .allEnemies, createdByUID: "system"),
        Skill(id: "sys_skill_aimed_shot", name: "Aimed Shot",
              description: "A carefully aimed shot that deals bonus DEX damage.",
              statAffected: .dex, modifier: 7, cooldownTurns: 2,
              targetType: .enemy, createdByUID: "system"),
        Skill(id: "sys_skill_hunters_mark", name: "Hunter's Mark",
              description: "Marks a target, increasing all damage dealt to it.",
              statAffected: .atk, modifier: 5, cooldownTurns: 3,
              targetType: .enemy, createdByUID: "system"),
        Skill(id: "sys_skill_shield_wall", name: "Shield Wall",
              description: "Raises a massive shield, greatly increasing DEF.",
              statAffected: .def, modifier: 12, cooldownTurns: 2,
              targetType: .self, createdByUID: "system"),
        Skill(id: "sys_skill_taunt", name: "Taunt",
              description: "Forces all enemies to attack the tank for one turn.",
              statAffected: .def, modifier: 6, cooldownTurns: 3,
              targetType: .enemy, createdByUID: "system")
    ]

    // MARK: — Default Inventory (D&D-style starter gear)

    static let defaultInventory: [InventoryItem] = [
        InventoryItem(id: "inv_health_potion", name: "Health Potion",
                      loreDescription: "A vial of crimson liquid that restores 20 HP when consumed.",
                      itemType: .consumable, modifier: 20, quantity: 3),
        InventoryItem(id: "inv_mana_potion", name: "Mana Potion",
                      loreDescription: "A shimmering blue potion that restores arcane energy.",
                      itemType: .consumable, modifier: 15, quantity: 2),
        InventoryItem(id: "inv_torch", name: "Torch",
                      loreDescription: "A simple torch. Keeps the dark at bay for a few hours.",
                      itemType: .keyItem, modifier: 0, quantity: 5),
        InventoryItem(id: "inv_rope", name: "Rope (50 ft)",
                      loreDescription: "Fifty feet of sturdy hempen rope. Essential for any adventurer.",
                      itemType: .keyItem, modifier: 0, quantity: 1),
        InventoryItem(id: "inv_rations", name: "Trail Rations",
                      loreDescription: "Dried meat, hard bread, and dried fruit. Enough for one day.",
                      itemType: .consumable, modifier: 5, quantity: 7),
        InventoryItem(id: "inv_bedroll", name: "Bedroll",
                      loreDescription: "A comfortable bedroll for sleeping in the wild.",
                      itemType: .keyItem, modifier: 0, quantity: 1),
        InventoryItem(id: "inv_dagger", name: "Dagger",
                      loreDescription: "A simple iron dagger. A backup weapon for when things go sideways.",
                      itemType: .passive, modifier: 2, quantity: 1),
        InventoryItem(id: "inv_healers_kit", name: "Healer's Kit",
                      loreDescription: "Bandages, herbs, and salves. Can stabilize a fallen companion.",
                      itemType: .consumable, modifier: 10, quantity: 1)
    ]
}
