import Foundation

struct InventoryItem: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var loreDescription: String
    var itemType: ItemType
    var modifier: Int
    var quantity: Int
}
