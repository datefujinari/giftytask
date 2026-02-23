import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firestore タスク DTO（tasks コレクション）
struct FirestoreTaskDTO: Codable {
    let id: String
    var title: String
    var senderId: String
    var receiverId: String
    var status: String // "pending" | "doing" | "done"
    var rewardId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
        case rewardId = "reward_id"
    }
}

// MARK: - Task Repository
/// Firestore の tasks コレクションへの送信・取得
@MainActor
final class TaskRepository: ObservableObject {
    static let shared = TaskRepository()
    
    private let db = Firestore.firestore()
    private let tasksCollection = "tasks"
    private let giftsCollection = "gifts"
    
    private init() {}
    
    /// タスクを他ユーザーへ送信する（tasks と gifts に保存、status は pending）
    /// - Parameters:
    ///   - title: タスク名
    ///   - giftName: ギフト名
    ///   - receiverId: 送信先ユーザーUID
    /// - Returns: 作成されたタスクIDとギフトID
    func sendTask(title: String, giftName: String, receiverId: String) async throws -> (taskId: String, giftId: String) {
        guard let senderId = Auth.auth().currentUser?.uid else {
            throw TaskRepositoryError.notAuthenticated
        }
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TaskRepositoryError.emptyTitle
        }
        guard !giftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TaskRepositoryError.emptyGiftName
        }
        guard !receiverId.isEmpty else {
            throw TaskRepositoryError.emptyReceiverId
        }
        
        let taskId = UUID().uuidString
        let giftId = UUID().uuidString
        
        let giftData: [String: Any] = [
            "id": giftId,
            "name": giftName.trimmingCharacters(in: .whitespacesAndNewlines),
            "is_unlocked": false,
            "associated_task_id": taskId
        ]
        
        let taskData: [String: Any] = [
            "id": taskId,
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "sender_id": senderId,
            "receiver_id": receiverId,
            "status": "pending",
            "reward_id": giftId
        ]
        
        let giftRef = db.collection(giftsCollection).document(giftId)
        let taskRef = db.collection(tasksCollection).document(taskId)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            giftRef.setData(giftData, merge: true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            taskRef.setData(taskData, merge: true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        
        return (taskId, giftId)
    }
}

// MARK: - Errors
enum TaskRepositoryError: LocalizedError {
    case notAuthenticated
    case emptyTitle
    case emptyGiftName
    case emptyReceiverId
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "ログインしていません"
        case .emptyTitle: return "タスク名を入力してください"
        case .emptyGiftName: return "ギフト名を入力してください"
        case .emptyReceiverId: return "相手のIDを指定してください"
        }
    }
}
