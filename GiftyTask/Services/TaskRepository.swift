import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firestore タスク DTO（tasks コレクション）
struct FirestoreTaskDTO: Codable, Identifiable {
    let id: String
    var title: String
    var senderId: String
    var receiverId: String
    var status: String
    var rewardId: String
    var giftName: String?
    var targetDays: Int
    var currentCount: Int
    var lastCompletedDate: Date?
    var senderName: String?
    var senderEmoji: String?
    var senderTotalCompletedCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case status
        case rewardId = "reward_id"
        case giftName = "gift_name"
        case targetDays = "target_days"
        case currentCount = "current_count"
        case lastCompletedDate = "last_completed_date"
        case senderName = "sender_name"
        case senderEmoji = "sender_emoji"
        case senderTotalCompletedCount = "sender_total_completed_count"
    }
    
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let senderId = data["sender_id"] as? String,
              let receiverId = data["receiver_id"] as? String,
              let status = data["status"] as? String,
              let rewardId = data["reward_id"] as? String else { return nil }
        self.id = id
        self.title = title
        self.senderId = senderId
        self.receiverId = receiverId
        self.status = status
        self.rewardId = rewardId
        self.giftName = data["gift_name"] as? String
        self.targetDays = (data["target_days"] as? Int) ?? 1
        self.currentCount = (data["current_count"] as? Int) ?? 0
        if let ts = data["last_completed_date"] as? Timestamp {
            self.lastCompletedDate = ts.dateValue()
        } else {
            self.lastCompletedDate = nil
        }
        self.senderName = data["sender_name"] as? String
        self.senderEmoji = data["sender_emoji"] as? String
        self.senderTotalCompletedCount = (data["sender_total_completed_count"] as? Int) ?? 0
    }
    
    /// 復活対象か（status==completed かつ 未達 かつ 最終完了が今日でない）
    func needsRevival(calendar: Calendar = .current) -> Bool {
        guard status == "completed", currentCount < targetDays,
              let last = lastCompletedDate else { return false }
        return !calendar.isDateInToday(last)
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
    ///   - targetDays: 目標日数（1〜30、未指定は1で単発）
    /// - Returns: 作成されたタスクIDとギフトID
    func sendTask(title: String, giftName: String, receiverId: String, targetDays: Int = 1) async throws -> (taskId: String, giftId: String) {
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
        let days = min(30, max(1, targetDays))
        
        let taskId = UUID().uuidString
        let giftId = UUID().uuidString
        
        let giftData: [String: Any] = [
            "id": giftId,
            "name": giftName.trimmingCharacters(in: .whitespacesAndNewlines),
            "is_unlocked": false,
            "associated_task_id": taskId
        ]
        
        let profile = AuthManager.shared.userProfile
        let senderName = profile?.displayName ?? "ユーザー"
        let senderEmoji = profile?.avatarEmoji ?? "👤"
        let senderTotal = profile?.totalCompletedCount ?? 0
        var taskData: [String: Any] = [
            "id": taskId,
            "title": title.trimmingCharacters(in: .whitespacesAndNewlines),
            "sender_id": senderId,
            "receiver_id": receiverId,
            "status": "pending",
            "reward_id": giftId,
            "gift_name": giftName.trimmingCharacters(in: .whitespacesAndNewlines),
            "target_days": days,
            "current_count": 0,
            "sender_name": senderName,
            "sender_emoji": senderEmoji,
            "sender_total_completed_count": senderTotal
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
    
    /// receiver_id が指定UIDと一致するタスクをリアルタイム購読する
    /// - Parameters:
    ///   - receiverId: 自分のUID
    ///   - onUpdate: スナップショット更新時にメインスレッドで呼ばれる（届いたタスクの配列）
    /// - Returns: 解除用の ListenerRegistration（不要になったら remove() を呼ぶ）
    func addReceivedTasksListener(
        receiverId: String,
        onUpdate: @escaping ([FirestoreTaskDTO]) -> Void
    ) -> ListenerRegistration {
        let query = db.collection(tasksCollection)
            .whereField("receiver_id", isEqualTo: receiverId)
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("TaskRepository addReceivedTasksListener error: \(error.localizedDescription)")
                DispatchQueue.main.async { onUpdate([]) }
                return
            }
            guard let documents = snapshot?.documents else {
                DispatchQueue.main.async { onUpdate([]) }
                return
            }
            let tasks = documents.compactMap { doc -> FirestoreTaskDTO? in
                FirestoreTaskDTO(data: doc.data())
            }
            DispatchQueue.main.async { onUpdate(tasks) }
        }
    }
    
    /// 届いたタスクを完了にする（累計: current_count+1、last_completed_date 更新。target_days に達した時のみギフトアンロック）
    func completeReceivedTask(taskId: String, rewardId: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TaskRepositoryError.notAuthenticated
        }
        let taskRef = db.collection(tasksCollection).document(taskId)
        let giftRef = db.collection(giftsCollection).document(rewardId)
        
        let doc: DocumentSnapshot = try await withCheckedThrowingContinuation { continuation in
            taskRef.getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "TaskRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "No snapshot"]))
                }
            }
        }
        guard let data = doc.data(),
              let current = data["current_count"] as? Int,
              let target = data["target_days"] as? Int else {
            return
        }
        let newCount = current + 1
        let now = Timestamp(date: Date())
        var update: [String: Any] = [
            "current_count": newCount,
            "last_completed_date": now,
            "status": "completed"
        ]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            taskRef.updateData(update) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        if newCount >= target {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                giftRef.updateData(["is_unlocked": true]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// 復活対象タスクの status を "active" に戻す（last_completed_date が今日でない場合）
    func reviveTask(taskId: String) async throws {
        guard Auth.auth().currentUser != nil else { return }
        let taskRef = db.collection(tasksCollection).document(taskId)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            taskRef.updateData(["status": "active"]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// タスクドキュメントを Firestore から削除
    func deleteTask(taskId: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TaskRepositoryError.notAuthenticated
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(tasksCollection).document(taskId).delete { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// 届いたタスクを「受け入れる」（受信者が承認）。tasks の status を "active" に更新する。
    func acceptReceivedTask(taskId: String, rewardId: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TaskRepositoryError.notAuthenticated
        }
        let taskRef = db.collection(tasksCollection).document(taskId)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            taskRef.updateData(["status": "active"]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
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
