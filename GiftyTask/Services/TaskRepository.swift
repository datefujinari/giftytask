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
    var completionImageURL: String?
    var dueDate: Date?
    var giftDescription: String?
    var createdByUserId: String?
    var createdByUserName: String?
    
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
        case completionImageURL = "completion_image_url"
        case dueDate = "due_date"
        case giftDescription = "gift_description"
        case createdByUserId = "created_by_uid"
        case createdByUserName = "created_by_name"
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
        self.completionImageURL = data["completion_image_url"] as? String
        if let dueTS = data["due_date"] as? Timestamp {
            self.dueDate = dueTS.dateValue()
        } else {
            self.dueDate = nil
        }
        self.giftDescription = data["gift_description"] as? String
        self.createdByUserId = data["created_by_uid"] as? String
        self.createdByUserName = data["created_by_name"] as? String
    }
    
    /// 復活対象か（status==completed かつ 未達 かつ 最終完了が今日でない）
    func needsRevival(calendar: Calendar = .current) -> Bool {
        guard status == "completed", currentCount < targetDays,
              let last = lastCompletedDate else { return false }
        return !calendar.isDateInToday(last)
    }
}

// MARK: - Firestore ルーティン提案 DTO（routine_suggestions コレクション）
struct FirestoreRoutineSuggestionDTO: Codable, Identifiable {
    let id: String
    var title: String
    var description: String?
    var targetCount: Int
    var associatedGiftName: String
    var senderId: String
    var receiverId: String
    var status: String
    var senderName: String?
    var createdAt: Date?
    
    init?(data: [String: Any]) {
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let targetCount = data["target_count"] as? Int,
              let associatedGiftName = data["associated_gift_name"] as? String,
              let senderId = data["sender_id"] as? String,
              let receiverId = data["receiver_id"] as? String,
              let status = data["status"] as? String else {
            return nil
        }
        self.id = id
        self.title = title
        self.description = data["description"] as? String
        self.targetCount = targetCount
        self.associatedGiftName = associatedGiftName
        self.senderId = senderId
        self.receiverId = receiverId
        self.status = status
        self.senderName = data["sender_name"] as? String
        if let ts = data["created_at"] as? Timestamp {
            self.createdAt = ts.dateValue()
        } else {
            self.createdAt = nil
        }
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
    private let routineSuggestionsCollection = "routine_suggestions"
    
    private init() {}
    
    /// タスクを他ユーザーへ送信する（tasks と gifts に保存、status は pending）
    /// - Parameters:
    ///   - title: タスク名
    ///   - giftName: ギフト名
    ///   - receiverId: 送信先ユーザーUID
    ///   - targetDays: 目標日数（1〜30、未指定は1で単発）
    /// - Returns: 作成されたタスクIDとギフトID
    func sendTask(
        title: String,
        giftName: String,
        receiverId: String,
        targetDays: Int = 1,
        dueDate: Date? = nil,
        giftDescription: String? = nil
    ) async throws -> (taskId: String, giftId: String) {
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
        
        let profile = AuthManager.shared.userProfile
        let senderName = profile?.displayName ?? "ユーザー"
        let senderEmoji = profile?.avatarEmoji ?? "👤"
        let senderTotal = profile?.totalCompletedCount ?? 0
        let trimmedGiftDescription = giftDescription
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40)) }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGiftName = giftName.trimmingCharacters(in: .whitespacesAndNewlines)

        var giftData: [String: Any] = [
            "id": giftId,
            "name": trimmedGiftName,
            "is_unlocked": false,
            "associated_task_id": taskId,
            "created_by_uid": senderId,
            "created_by_name": senderName,
            "task_title": trimmedTitle
        ]
        if let trimmedGiftDescription, !trimmedGiftDescription.isEmpty {
            giftData["description"] = trimmedGiftDescription
        }
        if let dueDate {
            giftData["task_due_date"] = Timestamp(date: dueDate)
        }

        var taskData: [String: Any] = [
            "id": taskId,
            "title": trimmedTitle,
            "sender_id": senderId,
            "receiver_id": receiverId,
            "status": "pending",
            "reward_id": giftId,
            "gift_name": trimmedGiftName,
            "target_days": days,
            "current_count": 0,
            "sender_name": senderName,
            "sender_emoji": senderEmoji,
            "sender_total_completed_count": senderTotal,
            "created_by_uid": senderId,
            "created_by_name": senderName
        ]
        if let dueDate {
            taskData["due_date"] = Timestamp(date: dueDate)
        }
        if let trimmedGiftDescription, !trimmedGiftDescription.isEmpty {
            taskData["gift_description"] = trimmedGiftDescription
        }
        
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
    
    /// ルーティン提案を他ユーザーへ送信する（routine_suggestions に status=pending で保存）
    func sendRoutineSuggestion(
        title: String,
        description: String?,
        targetCount: Int,
        associatedGiftName: String,
        receiverId: String
    ) async throws -> String {
        guard let senderId = Auth.auth().currentUser?.uid else {
            throw TaskRepositoryError.notAuthenticated
        }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGiftName = associatedGiftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReceiver = receiverId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedTitle.isEmpty else {
            throw TaskRepositoryError.emptyTitle
        }
        guard !trimmedGiftName.isEmpty else {
            throw TaskRepositoryError.emptyGiftName
        }
        guard !trimmedReceiver.isEmpty else {
            throw TaskRepositoryError.emptyReceiverId
        }
        
        let id = UUID().uuidString
        let senderName = AuthManager.shared.userProfile?.displayName ?? "ユーザー"
        let data: [String: Any] = [
            "id": id,
            "title": trimmedTitle,
            "description": (trimmedDescription?.isEmpty == false ? trimmedDescription! : NSNull()),
            "target_count": max(1, targetCount),
            "associated_gift_name": trimmedGiftName,
            "sender_id": senderId,
            "receiver_id": trimmedReceiver,
            "sender_name": senderName,
            "status": "pending",
            "created_at": Timestamp(date: Date())
        ]
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection(routineSuggestionsCollection).document(id).setData(data) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
        return id
    }
    
    /// sender_id が指定UIDと一致するタスクをリアルタイム購読（送信したタスク・承認待ち一覧用）
    func addSentTasksListener(
        senderId: String,
        onUpdate: @escaping ([FirestoreTaskDTO]) -> Void
    ) -> ListenerRegistration {
        let query = db.collection(tasksCollection)
            .whereField("sender_id", isEqualTo: senderId)
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("TaskRepository addSentTasksListener error: \(error.localizedDescription)")
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
    
    /// receiver_id が指定UIDのルーティン提案をリアルタイム購読する（受信BOX用）
    func addReceivedRoutineSuggestionsListener(
        receiverId: String,
        onUpdate: @escaping ([FirestoreRoutineSuggestionDTO]) -> Void
    ) -> ListenerRegistration {
        let query = db.collection(routineSuggestionsCollection)
            .whereField("receiver_id", isEqualTo: receiverId)
            .whereField("status", isEqualTo: "pending")
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("TaskRepository addReceivedRoutineSuggestionsListener error: \(error.localizedDescription)")
                DispatchQueue.main.async { onUpdate([]) }
                return
            }
            guard let documents = snapshot?.documents else {
                DispatchQueue.main.async { onUpdate([]) }
                return
            }
            let items = documents.compactMap { FirestoreRoutineSuggestionDTO(data: $0.data()) }
            DispatchQueue.main.async { onUpdate(items) }
        }
    }
    
    /// 届いたタスクの「完了報告」（画像任意）。status を "pending_approval" にし、送信者の承認を待つ。
    func reportTaskCompletion(taskId: String, rewardId: String, completionImageURL: String? = nil) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TaskRepositoryError.notAuthenticated
        }
        let taskRef = db.collection(tasksCollection).document(taskId)
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
              let current = data["current_count"] as? Int else {
            return
        }
        let newCount = current + 1
        let now = Timestamp(date: Date())
        var update: [String: Any] = [
            "current_count": newCount,
            "last_completed_date": now,
            "status": "pending_approval"
        ]
        if let url = completionImageURL, !url.isEmpty {
            update["completion_image_url"] = url
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            taskRef.updateData(update) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// 送信者が完了報告を「承認」。status を "completed" にし、ギフトをアンロック。
    func approveTaskCompletion(taskId: String, rewardId: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TaskRepositoryError.notAuthenticated
        }
        let taskRef = db.collection(tasksCollection).document(taskId)
        let giftRef = db.collection(giftsCollection).document(rewardId)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            taskRef.updateData(["status": "completed"]) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
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
    
    /// 送信者が完了報告を「差し戻し」。status を "active" に戻す。
    func rejectTaskCompletion(taskId: String) async throws {
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
    
    /// 届いたタスクの完了報告（画像なし・旧API互換）。status を "pending_approval" にする。承認は送信者が approveTaskCompletion で行う。
    func completeReceivedTask(taskId: String, rewardId: String) async throws {
        try await reportTaskCompletion(taskId: taskId, rewardId: rewardId, completionImageURL: nil)
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
    
    /// ルーティン提案を受け入れ済みに更新する
    func acceptRoutineSuggestion(suggestionId: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TaskRepositoryError.notAuthenticated
        }
        let ref = db.collection(routineSuggestionsCollection).document(suggestionId)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.updateData(["status": "accepted"]) { error in
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
