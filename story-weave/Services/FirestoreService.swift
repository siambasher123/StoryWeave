import FirebaseFirestore
import Foundation

class FirestoreService {
    static let shared = FirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Users

    func createUser(userId: String, email: String, completion: @escaping (Error?) -> Void) {
        db.collection("users").document(userId).setData([
            "email": email,
            "createdAt": Timestamp(date: Date()),
        ]) { error in
            completion(error)
        }
    }

    // MARK: - Stories

    /// Documents whose IDs are not valid UUIDs are silently skipped.
    /// All story documents in Firestore must use UUID-formatted document IDs.
    func fetchAllStories(completion: @escaping (Result<[StoryMeta], Error>) -> Void) {
        db.collection("stories").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let stories: [StoryMeta] = snapshot?.documents.compactMap { doc -> StoryMeta? in
                guard let uuid = UUID(uuidString: doc.documentID) else { return nil }
                let data = doc.data()
                guard
                    let title = data["title"] as? String,
                    let category = data["category"] as? String,
                    let description = data["description"] as? String,
                    let url = data["storyJsonURL"] as? String
                else { return nil }
                return StoryMeta(
                    id: uuid,
                    title: title,
                    category: category,
                    description: description,
                    storyJsonURL: url
                )
            } ?? []
            completion(.success(stories))
        }
    }

    // MARK: - Sessions

    func fetchSession(
        userId: String, storyId: UUID,
        completion: @escaping (Result<StorySession?, Error>) -> Void
    ) {
        let docId = "\(userId)_\(storyId.uuidString)"
        db.collection("sessions").document(docId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard
                let data = snapshot?.data(),
                let storyIdString = data["storyId"] as? String,
                let storyUUID = UUID(uuidString: storyIdString),
                let currentSceneId = data["currentSceneId"] as? String,
                let visitedSceneIds = data["visitedSceneIds"] as? [String],
                let isCompleted = data["isCompleted"] as? Bool,
                let timestamp = data["updatedAt"] as? Timestamp
            else {
                completion(.success(nil))
                return
            }
            let chosenChoiceIds = data["chosenChoiceIds"] as? [String] ?? []
            let totalScenes = data["totalScenes"] as? Int
            let session = StorySession(
                userId: userId,
                storyId: storyUUID,
                currentSceneId: currentSceneId,
                visitedSceneIds: visitedSceneIds,
                chosenChoiceIds: chosenChoiceIds,
                isCompleted: isCompleted,
                totalScenes: totalScenes,
                updatedAt: timestamp.dateValue()
            )
            completion(.success(session))
        }
    }

    func upsertSession(_ session: StorySession, completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "userId": session.userId,
            "storyId": session.storyId.uuidString,
            "currentSceneId": session.currentSceneId,
            "visitedSceneIds": session.visitedSceneIds,
            "chosenChoiceIds": session.chosenChoiceIds,
            "isCompleted": session.isCompleted,
            "updatedAt": Timestamp(date: session.updatedAt),
        ]
        if let total = session.totalScenes {
            data["totalScenes"] = total
        }
        db.collection("sessions").document(session.documentId).setData(data, merge: true) { error in
            completion(error)
        }
    }

    func deleteSession(userId: String, storyId: UUID, completion: @escaping (Error?) -> Void) {
        let docId = "\(userId)_\(storyId.uuidString)"
        db.collection("sessions").document(docId).delete { error in
            completion(error)
        }
    }

    func fetchUserSessions(
        userId: String, completion: @escaping (Result<[StorySession], Error>) -> Void
    ) {
        db.collection("sessions").whereField("userId", isEqualTo: userId).getDocuments {
            snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let sessions: [StorySession] = snapshot?.documents.compactMap { doc -> StorySession? in
                let data = doc.data()
                guard
                    let storyIdString = data["storyId"] as? String,
                    let storyId = UUID(uuidString: storyIdString),
                    let currentSceneId = data["currentSceneId"] as? String,
                    let visitedIds = data["visitedSceneIds"] as? [String],
                    let isCompleted = data["isCompleted"] as? Bool,
                    let timestamp = data["updatedAt"] as? Timestamp
                else { return nil }
                let chosenChoiceIds = data["chosenChoiceIds"] as? [String] ?? []
                let totalScenes = data["totalScenes"] as? Int
                return StorySession(
                    userId: userId,
                    storyId: storyId,
                    currentSceneId: currentSceneId,
                    visitedSceneIds: visitedIds,
                    chosenChoiceIds: chosenChoiceIds,
                    isCompleted: isCompleted,
                    totalScenes: totalScenes,
                    updatedAt: timestamp.dateValue()
                )
            } ?? []
            completion(.success(sessions))
        }
    }
}
