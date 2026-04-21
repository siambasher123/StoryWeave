import Foundation

enum ConnectionStatus: String, Codable, Sendable {
    case pending, accepted, declined
}

struct Connection: Codable, Identifiable, Sendable {
    let id: String          // [fromUID, toUID].sorted().joined(separator: "_")
    var fromUID: String
    var fromName: String
    var toUID: String
    var toName: String
    var status: ConnectionStatus
    var participants: [String]  // both UIDs — enables arrayContains queries
    var createdAt: Date

    func peer(for myUID: String) -> (uid: String, name: String) {
        fromUID == myUID
            ? (uid: toUID,   name: toName)
            : (uid: fromUID, name: fromName)
    }
}
