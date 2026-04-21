import Foundation

struct EnemyTemplate: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var emoji: String
    var hp: Int
    var atk: Int
    var def: Int
    var dex: Int

    init(id: String = UUID().uuidString, name: String, emoji: String,
         hp: Int, atk: Int, def: Int, dex: Int) {
        self.id = id; self.name = name; self.emoji = emoji
        self.hp = hp; self.atk = atk; self.def = def; self.dex = dex
    }
}

struct UserStoryScene: Codable, Identifiable, Sendable {
    let id: String
    var sceneType: SceneType
    var narrationText: String
    var choices: [String]           // choice labels (keys are their indices as strings)
    var nextSceneIDs: [String: String]  // choice index string → next scene ID
    var npcName: String?
    var enemies: [EnemyTemplate]?
    var skillCheckStat: StatType?
    var skillCheckDC: Int?
    var skillCheckSuccessSceneID: String?
    var skillCheckFailureSceneID: String?

    init(id: String = UUID().uuidString, sceneType: SceneType = .exploration,
         narrationText: String = "", choices: [String] = [],
         nextSceneIDs: [String: String] = [:]) {
        self.id = id; self.sceneType = sceneType; self.narrationText = narrationText
        self.choices = choices; self.nextSceneIDs = nextSceneIDs
    }
}

struct UserStory: Codable, Identifiable, Sendable {
    let id: String
    var authorUID: String
    var authorName: String
    var title: String
    var synopsis: String
    var scenes: [UserStoryScene]    // max 40
    var startSceneID: String
    var isPublished: Bool
    var createdAt: Date
    var playCount: Int

    init(id: String = UUID().uuidString, authorUID: String, authorName: String,
         title: String = "", synopsis: String = "") {
        self.id = id; self.authorUID = authorUID; self.authorName = authorName
        self.title = title; self.synopsis = synopsis
        self.scenes = []; self.startSceneID = ""
        self.isPublished = false; self.createdAt = Date(); self.playCount = 0
    }
}
