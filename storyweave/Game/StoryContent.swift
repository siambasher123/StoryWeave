import Foundation

// MARK: — Scene support types

/// Represents a combat enemy with stats and visual presentation
/// - id: Unique identifier for the enemy instance
/// - name: Display name for the enemy
/// - emoji: Visual representation in the UI
/// - hp/maxHP: Current and maximum health points
/// - atk/def/dex: Combat stats (attack, defense, dexterity)
struct Enemy: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let emoji: String
    let hp: Int
    let maxHP: Int
    let atk: Int
    let def: Int
    let dex: Int
}

/// Configuration for combat encounters
/// Specifies enemies and optional escape options
struct CombatConfig: Sendable {
    let enemies: [Enemy]
    let fleeSceneID: String?
}

/// Configuration for skill check/ability checks within a scene
/// Tests a specific stat against a difficulty check
struct SkillCheckConfig: Sendable {
    let stat: StatType
    let difficultyDC: Int
    let successSceneID: String
    let failureSceneID: String
}

/// Represents a single Act in the narrative campaign
/// Contains multiple scenes that comprise a chapter
struct Act: Identifiable, Sendable {
    let id: Int
    let title: String
    let theme: String
    let scenes: [GameScene]
}

/// A single scene in the game world
/// Can be exploration, dialogue, combat, or skill check based
struct GameScene: Identifiable, Sendable {
    let id: String
    let actIndex: Int
    let sceneType: SceneType
    let narrationSeed: String
    let choices: [SceneChoice]
    let nextSceneIDs: [String: String]
    let combat: CombatConfig?
    let skillCheck: SkillCheckConfig?
    let npcName: String?

    init(id: String, actIndex: Int, sceneType: SceneType, narrationSeed: String,
         choices: [SceneChoice], nextSceneIDs: [String: String],
         combat: CombatConfig? = nil, skillCheck: SkillCheckConfig? = nil, npcName: String? = nil) {
        self.id = id
        self.actIndex = actIndex
        self.sceneType = sceneType
        self.narrationSeed = narrationSeed
        self.choices = choices
        self.nextSceneIDs = nextSceneIDs
        self.combat = combat
        self.skillCheck = skillCheck
        self.npcName = npcName
    }
}

/// A selectable choice presented to the player in a scene
struct SceneChoice: Codable, Identifiable, Sendable {
    let id: String
    let key: String
    let label: String
}

// MARK: — Enemy presets

/// Pre-configured enemy definitions used throughout the campaign
/// Factory methods generate unique instances with parameterized IDs
private enum EnemyPreset {
    /// Weak melee enemies encountered early game
    /// High DEX for quick attacks, low stats overall
    static func goblinScout(_ n: Int) -> Enemy {
        Enemy(id: "goblin_scout_\(n)", name: "Goblin Scout", emoji: "👺",
              hp: 18, maxHP: 18, atk: 5, def: 2, dex: 8)
    }
    /// Mid-game ghost enemy with balanced stats
    static let shadowWraith = Enemy(id: "shadow_wraith", name: "Shadow Wraith", emoji: "👻",
                                    hp: 35, maxHP: 35, atk: 8, def: 3, dex: 7)
    /// Underdark crawlers - melee threats with moderate difficulty
    static func darkPatrol(_ n: Int) -> Enemy {
        Enemy(id: "dark_patrol_\(n)", name: "Underdark Crawler", emoji: "🦂",
              hp: 28, maxHP: 28, atk: 9, def: 5, dex: 6)
    }
    /// Mid-game fungal enemy with high defense but low speed
    static let sporeGuardian = Enemy(id: "spore_guardian", name: "Spore Guardian", emoji: "🍄",
                                     hp: 40, maxHP: 40, atk: 7, def: 8, dex: 3)
    /// Act 3 mirror encounters - reflections of party members
    static func mirrorSelf(_ n: Int) -> Enemy {
        Enemy(id: "mirror_self_\(n)", name: "Mirror Shade", emoji: "🪞",
              hp: 30, maxHP: 30, atk: 10, def: 4, dex: 9)
    }
    /// Act 3+ elite enemy with high attack and dexterity
    static func drow(_ n: Int) -> Enemy {
        Enemy(id: "drow_\(n)", name: "Drow Warrior", emoji: "🧝",
              hp: 38, maxHP: 38, atk: 11, def: 7, dex: 10)
    }
    /// Act 4 guardian boss - extremely high HP and defense
    static let ancientGuardian = Enemy(id: "ancient_guardian", name: "Ancient Guardian", emoji: "🗿",
                                       hp: 70, maxHP: 70, atk: 14, def: 12, dex: 5)
    /// Act 4 final boss - the main antagonist
    static let darkEntityP1 = Enemy(id: "dark_entity_p1", name: "Void Harbinger", emoji: "🌑",
                                    hp: 90, maxHP: 90, atk: 16, def: 8, dex: 10)
    /// Act 5 encounter used for specific ending paths
    static let reflectionEnemy = Enemy(id: "reflection_beast", name: "Corruption Wraith", emoji: "💀",
                                       hp: 45, maxHP: 45, atk: 12, def: 6, dex: 8)
}

// MARK: — StoryContent

/// Central repository for all campaign content
/// Provides access to all 5 acts and their scenes through static methods
struct StoryContent {
    /// All acts in order of campaign progression
    static let acts: [Act] = [act1, act2, act3, act4, act5]

    /// Retrieves a scene by its unique ID from any act
    /// - Parameter id: Scene identifier (e.g., "act1_scene1")
    /// - Returns: GameScene if found, nil otherwise
    static func scene(id: String) -> GameScene? {
        acts.flatMap(\.scenes).first(where: { $0.id == id })
    }

    // MARK: Act 1 — The Gathering Dark (7 scenes)

    private static let a1_s1 = GameScene(
        id: "act1_scene1", actIndex: 0, sceneType: .exploration,
        narrationSeed: "Your party stands at the edge of Ashenvale village as twilight devours the last amber light. Ancient ruins crown the hillside ahead — and something in their shadows moves with terrible purpose.",
        choices: [
            SceneChoice(id: "c1", key: "investigate", label: "Investigate the ruins"),
            SceneChoice(id: "c2", key: "scout",       label: "Send a scout ahead"),
            SceneChoice(id: "c3", key: "rest",        label: "Set up camp and rest")
        ],
        nextSceneIDs: ["investigate": "act1_scene2", "scout": "act1_scene2", "rest": "act1_scene3"]
    )

    private static let a1_s2 = GameScene(
        id: "act1_scene2", actIndex: 0, sceneType: .dialogue,
        narrationSeed: "A hooded figure steps from behind a crumbling archway. Her eyes carry the silver gleam of someone who has seen too much. 'You should not be here,' she says quietly, 'but then — neither should I.'",
        choices: [
            SceneChoice(id: "c1", key: "trust",     label: "Trust her warning"),
            SceneChoice(id: "c2", key: "challenge", label: "Challenge her motives")
        ],
        nextSceneIDs: ["trust": "act1_scene4", "challenge": "act1_scene4"],
        npcName: "Seraphine"
    )

    private static let a1_s3 = GameScene(
        id: "act1_scene3", actIndex: 0, sceneType: .skillCheck,
        narrationSeed: "As the party makes camp, shadows move unnaturally at the treeline. Something watches. Stay still and observe without revealing yourself.",
        choices: [],
        nextSceneIDs: [:],
        skillCheck: SkillCheckConfig(stat: .dex, difficultyDC: 12,
                                     successSceneID: "act1_scene4",
                                     failureSceneID: "act1_scene4")
    )

    private static let a1_s4 = GameScene(
        id: "act1_scene4", actIndex: 0, sceneType: .exploration,
        narrationSeed: "The ruins open into a broad courtyard choked with withered vines. Strange glyphs pulse with dim violet light on the stone walls. The entrance to the main hall yawns ahead like a screaming mouth.",
        choices: [
            SceneChoice(id: "c1", key: "enter", label: "Enter the main hall"),
            SceneChoice(id: "c2", key: "study", label: "Study the glyphs first")
        ],
        nextSceneIDs: ["enter": "act1_scene5", "study": "act1_scene5"]
    )

    private static let a1_s5 = GameScene(
        id: "act1_scene5", actIndex: 0, sceneType: .combat,
        narrationSeed: "Goblin scouts explode from hiding places in the rubble, shrieking battle cries. Three of them — fast, vicious, and very hungry.",
        choices: [],
        nextSceneIDs: ["victory": "act1_scene6", "defeat": "game_over"],
        combat: CombatConfig(
            enemies: [EnemyPreset.goblinScout(1), EnemyPreset.goblinScout(2), EnemyPreset.goblinScout(3)],
            fleeSceneID: "act1_scene4"
        )
    )

    private static let a1_s6 = GameScene(
        id: "act1_scene6", actIndex: 0, sceneType: .exploration,
        narrationSeed: "The goblins scatter. Among the debris you find a torn journal page with one legible line: 'The Seal of Etherion breaks at the third convergence.' Whatever that means — it feels important.",
        choices: [
            SceneChoice(id: "c1", key: "keep",   label: "Keep the journal page"),
            SceneChoice(id: "c2", key: "discard", label: "Leave it — likely nonsense")
        ],
        nextSceneIDs: ["keep": "act1_scene7", "discard": "act1_scene7"]
    )

    private static let a1_s7 = GameScene(
        id: "act1_scene7", actIndex: 0, sceneType: .exploration,
        narrationSeed: "Night has fully fallen. Below the ruins, a staircase descends into absolute darkness. The air that rises from it is cold in a way that has nothing to do with temperature. The Underdark awaits.",
        choices: [
            SceneChoice(id: "c1", key: "descend", label: "Descend into the dark")
        ],
        nextSceneIDs: ["descend": "act2_scene1"]
    )

    static let act1 = Act(
        id: 0, title: "The Gathering Dark",
        theme: "Introduction, world-building, first combat",
        scenes: [a1_s1, a1_s2, a1_s3, a1_s4, a1_s5, a1_s6, a1_s7]
    )

    // MARK: Act 2 — Into the Underdark (8 scenes)

    private static let a2_s1 = GameScene(
        id: "act2_scene1", actIndex: 1, sceneType: .exploration,
        narrationSeed: "The Underdark swallows you whole. Bioluminescent fungi cast a sickly blue glow across walls that drip with moisture. Two passages branch before you — the left reeks of sulfur, the right of blood.",
        choices: [
            SceneChoice(id: "c1", key: "left",  label: "Take the left passage"),
            SceneChoice(id: "c2", key: "right", label: "Take the right passage")
        ],
        nextSceneIDs: ["left": "act2_scene2", "right": "act2_scene3"]
    )

    private static let a2_s2 = GameScene(
        id: "act2_scene2", actIndex: 1, sceneType: .combat,
        narrationSeed: "An Underdark patrol emerges from a side tunnel — three crawlers that move like nightmares on too many legs. They've already cut off your retreat.",
        choices: [],
        nextSceneIDs: ["victory": "act2_scene4", "defeat": "game_over"],
        combat: CombatConfig(
            enemies: [EnemyPreset.darkPatrol(1), EnemyPreset.darkPatrol(2), EnemyPreset.darkPatrol(3)],
            fleeSceneID: "act2_scene1"
        )
    )

    private static let a2_s3 = GameScene(
        id: "act2_scene3", actIndex: 1, sceneType: .dialogue,
        narrationSeed: "A drow prisoner hangs from chains in a side alcove, her wounds fresh. She looks up with wariness, not fear. 'Free me,' she says, 'and I'll show you what lurks ahead. Ignore me and walk into a trap.'",
        choices: [
            SceneChoice(id: "c1", key: "free",   label: "Free the prisoner"),
            SceneChoice(id: "c2", key: "ignore", label: "Leave her and press on")
        ],
        nextSceneIDs: ["free": "act2_scene4", "ignore": "act2_scene4"],
        npcName: "Zilvara"
    )

    private static let a2_s4 = GameScene(
        id: "act2_scene4", actIndex: 1, sceneType: .exploration,
        narrationSeed: "A vast cavern opens around you, its ceiling lost in darkness. Enormous fungi tower overhead, their caps glowing amber and violet. Something moves between the stalks — rhythmic, patient, hungry.",
        choices: [
            SceneChoice(id: "c1", key: "stealth",   label: "Attempt to sneak through"),
            SceneChoice(id: "c2", key: "distract",  label: "Create a distraction and run")
        ],
        nextSceneIDs: ["stealth": "act2_scene5", "distract": "act2_scene5"]
    )

    private static let a2_s5 = GameScene(
        id: "act2_scene5", actIndex: 1, sceneType: .skillCheck,
        narrationSeed: "The spore creatures sense vibration. Every footstep must be placed with surgical precision. One mistake and the whole colony wakes.",
        choices: [],
        nextSceneIDs: [:],
        skillCheck: SkillCheckConfig(stat: .dex, difficultyDC: 14,
                                     successSceneID: "act2_scene6",
                                     failureSceneID: "act2_scene7")
    )

    private static let a2_s6 = GameScene(
        id: "act2_scene6", actIndex: 1, sceneType: .dialogue,
        narrationSeed: "Beyond the fungal grove, your guide (or the path you chose) leads to a hidden chamber. Scrawled on the wall in fresh charcoal: 'Malachar walks again. He wears a friend's face.' A betrayal is coming — but whose?",
        choices: [
            SceneChoice(id: "c1", key: "believe",  label: "Take the warning seriously"),
            SceneChoice(id: "c2", key: "dismiss",  label: "Dismiss it as propaganda")
        ],
        nextSceneIDs: ["believe": "act2_scene8", "dismiss": "act2_scene8"],
        npcName: "Unknown Author"
    )

    private static let a2_s7 = GameScene(
        id: "act2_scene7", actIndex: 1, sceneType: .combat,
        narrationSeed: "The colony erupts. Spore guardians rise from the fungal mat, their attacks releasing clouds of hallucinogenic spores. Fight through or be consumed by visions.",
        choices: [],
        nextSceneIDs: ["victory": "act2_scene6", "defeat": "game_over"],
        combat: CombatConfig(
            enemies: [EnemyPreset.sporeGuardian, EnemyPreset.sporeGuardian],
            fleeSceneID: "act2_scene5"
        )
    )

    private static let a2_s8 = GameScene(
        id: "act2_scene8", actIndex: 1, sceneType: .exploration,
        narrationSeed: "You emerge from the Underdark's second level into a gallery of twisted black stone. The ceiling here is carved with scenes of conquest — armies bowing to a robed figure whose face has been deliberately scratched away.",
        choices: [
            SceneChoice(id: "c1", key: "deeper", label: "Press deeper — the answer lies below")
        ],
        nextSceneIDs: ["deeper": "act3_scene1"]
    )

    static let act2 = Act(
        id: 1, title: "Into the Underdark",
        theme: "Rising stakes, betrayal hints, moral choices",
        scenes: [a2_s1, a2_s2, a2_s3, a2_s4, a2_s5, a2_s6, a2_s7, a2_s8]
    )

    // MARK: Act 3 — The Mirror Fracture (9 scenes)

    private static let a3_s1 = GameScene(
        id: "act3_scene1", actIndex: 2, sceneType: .exploration,
        narrationSeed: "A circular chamber dominates the cavern. At its center: a mirror ten feet tall, framed in black iron wrought in the shape of screaming figures. Your reflections in it are wrong — they move a half-second behind you, and they're smiling.",
        choices: [
            SceneChoice(id: "c1", key: "approach", label: "Approach the mirror"),
            SceneChoice(id: "c2", key: "circle",   label: "Circle the room first")
        ],
        nextSceneIDs: ["approach": "act3_scene2", "circle": "act3_scene2"]
    )

    private static let a3_s2 = GameScene(
        id: "act3_scene2", actIndex: 2, sceneType: .dialogue,
        narrationSeed: "A voice from within the mirror speaks — not aloud, but directly into each party member's mind simultaneously, saying different things to each. It offers power. It offers truth. It offers a shortcut. Use it, or destroy it?",
        choices: [
            SceneChoice(id: "c1", key: "use",     label: "Use the mirror's power"),
            SceneChoice(id: "c2", key: "destroy", label: "Destroy it — no good comes from this")
        ],
        nextSceneIDs: ["use": "act3_scene3", "destroy": "act3_scene5"],
        npcName: "The Mirror Voice"
    )

    private static let a3_s3 = GameScene(
        id: "act3_scene3", actIndex: 2, sceneType: .skillCheck,
        narrationSeed: "You reach into the mirror's power. It is vast and cold and very aware. An intellect check determines whether you bend it to your will — or it bends you.",
        choices: [],
        nextSceneIDs: [:],
        skillCheck: SkillCheckConfig(stat: .intel, difficultyDC: 15,
                                     successSceneID: "act3_scene4",
                                     failureSceneID: "act3_scene6")
    )

    private static let a3_s4 = GameScene(
        id: "act3_scene4", actIndex: 2, sceneType: .exploration,
        narrationSeed: "The mirror obeys. It shows you the path forward: the dark entity's lair, its weaknesses, the exact moment it can be destroyed. The vision is brutally clear — and it costs Zilvara everything. She knew this when she helped you.",
        choices: [
            SceneChoice(id: "c1", key: "forward", label: "Use the knowledge and press on")
        ],
        nextSceneIDs: ["forward": "act3_scene7"]
    )

    private static let a3_s5 = GameScene(
        id: "act3_scene5", actIndex: 2, sceneType: .combat,
        narrationSeed: "The mirror shatters with a sound like a thousand voices screaming. The fragments rise. From each piece steps a shadow-self — reflections of your worst impulses given solid form.",
        choices: [],
        nextSceneIDs: ["victory": "act3_scene7", "defeat": "game_over"],
        combat: CombatConfig(
            enemies: [EnemyPreset.mirrorSelf(1), EnemyPreset.mirrorSelf(2)],
            fleeSceneID: "act3_scene2"
        )
    )

    private static let a3_s6 = GameScene(
        id: "act3_scene6", actIndex: 2, sceneType: .exploration,
        narrationSeed: "The mirror's power twists back on you. For a moment you see yourself through its eyes — flawed, frightened, but somehow still standing. When the vision clears, you're on the floor. Your companions are helping you up. You're weaker, but wiser.",
        choices: [
            SceneChoice(id: "c1", key: "recover", label: "Gather yourself and continue")
        ],
        nextSceneIDs: ["recover": "act3_scene7"]
    )

    private static let a3_s7 = GameScene(
        id: "act3_scene7", actIndex: 2, sceneType: .skillCheck,
        narrationSeed: "A party member collapses from the mirror's residual effect. You can stop now and save them — or press on while they recover on their own. The entity grows stronger every moment you delay.",
        choices: [],
        nextSceneIDs: [:],
        skillCheck: SkillCheckConfig(stat: .intel, difficultyDC: 12,
                                     successSceneID: "act3_scene8",
                                     failureSceneID: "act3_scene8")
    )

    private static let a3_s8 = GameScene(
        id: "act3_scene8", actIndex: 2, sceneType: .combat,
        narrationSeed: "Drow warriors ambush the party — they serve the entity and have been tracking you since the Underdark's first level. They fight with lethal precision.",
        choices: [],
        nextSceneIDs: ["victory": "act3_scene9", "defeat": "game_over"],
        combat: CombatConfig(
            enemies: [EnemyPreset.drow(1), EnemyPreset.drow(2)],
            fleeSceneID: "act3_scene7"
        )
    )

    private static let a3_s9 = GameScene(
        id: "act3_scene9", actIndex: 2, sceneType: .exploration,
        narrationSeed: "The survivors regroup in a hidden alcove. Wounds are bandaged, provisions shared. There's less laughter than before. What you've seen in the mirror — each other's darkest reflections — hangs between you unspoken. But you're still here. Together.",
        choices: [
            SceneChoice(id: "c1", key: "continue", label: "Descend to the final level")
        ],
        nextSceneIDs: ["continue": "act4_scene1"]
    )

    static let act3 = Act(
        id: 2, title: "The Mirror Fracture",
        theme: "Mid-game twist, moral dilemma, party bonds tested",
        scenes: [a3_s1, a3_s2, a3_s3, a3_s4, a3_s5, a3_s6, a3_s7, a3_s8, a3_s9]
    )

    // MARK: Act 4 — The Final Descent (9 scenes)

    private static let a4_s1 = GameScene(
        id: "act4_scene1", actIndex: 3, sceneType: .exploration,
        narrationSeed: "The final passage opens into a cavern so vast it has its own weather. Lightning arcs between stone spires. At the center: a fortress built of compressed darkness, its gates sealed with chains of pure void. This is where the entity has been feeding.",
        choices: [
            SceneChoice(id: "c1", key: "charge",  label: "Charge — catch it off guard"),
            SceneChoice(id: "c2", key: "prepare", label: "Take time to prepare properly")
        ],
        nextSceneIDs: ["charge": "act4_scene2", "prepare": "act4_scene3"]
    )

    private static let a4_s2 = GameScene(
        id: "act4_scene2", actIndex: 3, sceneType: .combat,
        narrationSeed: "The Ancient Guardian — a construct of compressed shadow and stone — stands between you and the fortress. It was built to protect this place from exactly what you are. It is very good at its job.",
        choices: [],
        nextSceneIDs: ["victory": "act4_scene4", "defeat": "game_over"],
        combat: CombatConfig(
            enemies: [EnemyPreset.ancientGuardian],
            fleeSceneID: "act4_scene1"
        )
    )

    private static let a4_s3 = GameScene(
        id: "act4_scene3", actIndex: 3, sceneType: .skillCheck,
        narrationSeed: "You study the fortress's defenses before striking. There are patterns — weaknesses, gaps, a moment of vulnerability that comes once every hour. An intelligence check determines whether you find it in time.",
        choices: [],
        nextSceneIDs: [:],
        skillCheck: SkillCheckConfig(stat: .intel, difficultyDC: 13,
                                     successSceneID: "act4_scene4",
                                     failureSceneID: "act4_scene4")
    )

    private static let a4_s4 = GameScene(
        id: "act4_scene4", actIndex: 3, sceneType: .exploration,
        narrationSeed: "Inside the fortress, reality bends. Corridors that should meet don't. Rooms repeat. At the heart of it all, a presence pulses — ancient, vast, and very, very patient. Then it notices you.",
        choices: [
            SceneChoice(id: "c1", key: "confront", label: "Confront the entity directly"),
            SceneChoice(id: "c2", key: "seek",     label: "Seek its hidden weakness first")
        ],
        nextSceneIDs: ["confront": "act4_scene5", "seek": "act4_scene6"]
    )

    private static let a4_s5 = GameScene(
        id: "act4_scene5", actIndex: 3, sceneType: .dialogue,
        narrationSeed: "The Void Harbinger speaks: not in words but in sensation — the feeling of being absolutely alone. It offers surrender. It promises that the transition will be painless. That you'll still exist, in a sense, as part of it.",
        choices: [
            SceneChoice(id: "c1", key: "refuse",    label: "Refuse — you did not come this far to fail"),
            SceneChoice(id: "c2", key: "negotiate", label: "Negotiate — find a third option")
        ],
        nextSceneIDs: ["refuse": "act4_scene8", "negotiate": "act4_scene7"],
        npcName: "The Void Harbinger"
    )

    private static let a4_s6 = GameScene(
        id: "act4_scene6", actIndex: 3, sceneType: .skillCheck,
        narrationSeed: "You search for the entity's true core — the original wound in reality that it crawled through. It's buried beneath layers of corrupted energy. An intelligence check determines whether you can pinpoint it before it detects you.",
        choices: [],
        nextSceneIDs: [:],
        skillCheck: SkillCheckConfig(stat: .intel, difficultyDC: 16,
                                     successSceneID: "act4_scene8",
                                     failureSceneID: "act4_scene8")
    )

    private static let a4_s7 = GameScene(
        id: "act4_scene7", actIndex: 3, sceneType: .exploration,
        narrationSeed: "The entity offers a dark compact: take its power as your own, use it to protect the world from other threats, and let this one pass. It is not lying about the power. It is not lying about the other threats. Whether it can be trusted with the cost — that is the question.",
        choices: [
            SceneChoice(id: "c1", key: "accept", label: "Accept the compact — use its power"),
            SceneChoice(id: "c2", key: "refuse",  label: "Refuse and fight")
        ],
        nextSceneIDs: ["accept": "act4_scene9", "refuse": "act4_scene8"]
    )

    private static let a4_s8 = GameScene(
        id: "act4_scene8", actIndex: 3, sceneType: .combat,
        narrationSeed: "The Void Harbinger descends. Reality warps around it. Every strike you land costs something — memory, time, possibility. But so does every moment you don't fight.",
        choices: [],
        nextSceneIDs: ["victory": "act4_scene9", "defeat": "game_over"],
        combat: CombatConfig(
            enemies: [EnemyPreset.darkEntityP1],
            fleeSceneID: nil
        )
    )

    private static let a4_s9 = GameScene(
        id: "act4_scene9", actIndex: 3, sceneType: .exploration,
        narrationSeed: "The entity is diminished — wounded, perhaps mortally. But a wound like this requires more than steel to seal. Someone must give something irreplaceable to close the breach permanently.",
        choices: [
            SceneChoice(id: "c1", key: "self_sacrifice", label: "Offer your own memories — seal it with self"),
            SceneChoice(id: "c2", key: "use_artifact",   label: "Use the journal artifact to bind it"),
            SceneChoice(id: "c3", key: "shared_cost",    label: "Share the cost — every party member gives a fragment")
        ],
        nextSceneIDs: ["self_sacrifice": "act5_entry", "use_artifact": "act5_entry", "shared_cost": "act5_entry"]
    )

    static let act4 = Act(
        id: 3, title: "The Final Descent",
        theme: "Climax, boss encounter, sacrifice and consequence",
        scenes: [a4_s1, a4_s2, a4_s3, a4_s4, a4_s5, a4_s6, a4_s7, a4_s8, a4_s9]
    )

    // MARK: Act 5 — Echoes (5 scenes, branching by decisions)

    private static let a5_entry = GameScene(
        id: "act5_entry", actIndex: 4, sceneType: .exploration,
        narrationSeed: "The breach is sealed. The fortress collapses. You climb back toward light that you were not sure you'd ever see again.",
        choices: [
            SceneChoice(id: "c1", key: "epilogue", label: "Face the aftermath")
        ],
        nextSceneIDs: ["epilogue": "act5_heroic"] // SceneManager overrides this based on decisions
    )

    static let act5_heroic = GameScene(
        id: "act5_heroic", actIndex: 4, sceneType: .exploration,
        narrationSeed: "You emerge to a dawn that seems brighter than it has any right to be. The village of Ashenvale is intact. Your companions are alive and whole. The darkness is sealed. In the weeks that follow, songs are written. They don't capture what it actually felt like — nothing could — but they try. You let them. The world deserves its heroes.",
        choices: [SceneChoice(id: "c1", key: "end", label: "Your legend begins")],
        nextSceneIDs: ["end": "game_complete"]
    )

    static let act5_pyrrhic = GameScene(
        id: "act5_pyrrhic", actIndex: 4, sceneType: .exploration,
        narrationSeed: "You emerge from the ruins carrying the weight of what was lost. Not everyone made it. The breach is sealed — the world is safe — but the cost sits heavy on the survivors. The songs they write about you will be quieter. More honest. They'll be sung in minor keys, and old warriors who hear them will look away.",
        choices: [SceneChoice(id: "c1", key: "end", label: "Carry what you've lost")],
        nextSceneIDs: ["end": "game_complete"]
    )

    static let act5_dark = GameScene(
        id: "act5_dark", actIndex: 4, sceneType: .exploration,
        narrationSeed: "You accepted the compact, and the power is yours. The entity is bound, not destroyed — and you feel it always now, at the edge of thought, patient. You have protected the world, yes. You have also changed in ways you cannot fully measure. Your companions watch you differently. Some with admiration. Some with fear. Some with both.",
        choices: [SceneChoice(id: "c1", key: "end", label: "Step into the uncertain future")],
        nextSceneIDs: ["end": "game_complete"]
    )

    static let act5_true = GameScene(
        id: "act5_true", actIndex: 4, sceneType: .exploration,
        narrationSeed: "You chose every right thing — and the world feels it. The prisoner you freed became a bridge between peoples. The guide you believed kept faith. The companion you saved lived to do something beautiful. The darkness is sealed with the artifact, costing nothing of yourself, because you spent the whole journey building the trust and knowledge that made a clean ending possible. Some victories are earned long before the final battle.",
        choices: [SceneChoice(id: "c1", key: "end", label: "Rest — you've earned it")],
        nextSceneIDs: ["end": "game_complete"]
    )

    static let act5 = Act(
        id: 4, title: "Echoes",
        theme: "Consequence-driven epilogue — four distinct endings",
        scenes: [a5_entry, act5_heroic, act5_pyrrhic, act5_dark, act5_true]
    )
}
