import Foundation

struct Character: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var archetype: Archetype
    var hp: Int
    var maxHP: Int
    var atk: Int
    var def: Int
    var dex: Int
    var intel: Int
    var skills: [String]
    var createdByUID: String
    var loreDescription: String
    var level: Int
    var xp: Int
    var portraitURL: String?
}
