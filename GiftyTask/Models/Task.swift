import Foundation

// MARK: - Task Model
struct Task: Identifiable, Codable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id, title, description, epicId, status, verificationMode, priority
        case dueDate, completedDate, photoEvidenceURL, createdAt, updatedAt
        case xpReward, rewardDisplayName, isRoutine, senderId, fromDisplayName, rewardId
        case targetDays, currentCount, lastCompletedDate
        case senderName, senderEmoji, senderTotalCompletedCount
        case completionImageURL
        case createdByUserId, createdByUserName
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        epicId = try c.decodeIfPresent(String.self, forKey: .epicId)
        status = try c.decode(TaskStatus.self, forKey: .status)
        verificationMode = try c.decode(VerificationMode.self, forKey: .verificationMode)
        priority = try c.decode(TaskPriority.self, forKey: .priority)
        dueDate = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        completedDate = try c.decodeIfPresent(Date.self, forKey: .completedDate)
        photoEvidenceURL = try c.decodeIfPresent(String.self, forKey: .photoEvidenceURL)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        xpReward = try c.decodeIfPresent(Int.self, forKey: .xpReward) ?? 10
        rewardDisplayName = try c.decodeIfPresent(String.self, forKey: .rewardDisplayName)
        isRoutine = try c.decodeIfPresent(Bool.self, forKey: .isRoutine) ?? false
        senderId = try c.decodeIfPresent(String.self, forKey: .senderId)
        fromDisplayName = try c.decodeIfPresent(String.self, forKey: .fromDisplayName)
        rewardId = try c.decodeIfPresent(String.self, forKey: .rewardId)
        targetDays = try c.decodeIfPresent(Int.self, forKey: .targetDays) ?? 1
        currentCount = try c.decodeIfPresent(Int.self, forKey: .currentCount) ?? 0
        lastCompletedDate = try c.decodeIfPresent(Date.self, forKey: .lastCompletedDate)
        senderName = try c.decodeIfPresent(String.self, forKey: .senderName)
        senderEmoji = try c.decodeIfPresent(String.self, forKey: .senderEmoji)
        senderTotalCompletedCount = try c.decodeIfPresent(Int.self, forKey: .senderTotalCompletedCount) ?? 0
        completionImageURL = try c.decodeIfPresent(String.self, forKey: .completionImageURL)
        createdByUserId = try c.decodeIfPresent(String.self, forKey: .createdByUserId)
        createdByUserName = try c.decodeIfPresent(String.self, forKey: .createdByUserName)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(epicId, forKey: .epicId)
        try c.encode(status, forKey: .status)
        try c.encode(verificationMode, forKey: .verificationMode)
        try c.encode(priority, forKey: .priority)
        try c.encodeIfPresent(dueDate, forKey: .dueDate)
        try c.encodeIfPresent(completedDate, forKey: .completedDate)
        try c.encodeIfPresent(photoEvidenceURL, forKey: .photoEvidenceURL)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(xpReward, forKey: .xpReward)
        try c.encodeIfPresent(rewardDisplayName, forKey: .rewardDisplayName)
        try c.encode(isRoutine, forKey: .isRoutine)
        try c.encodeIfPresent(senderId, forKey: .senderId)
        try c.encodeIfPresent(fromDisplayName, forKey: .fromDisplayName)
        try c.encodeIfPresent(rewardId, forKey: .rewardId)
        try c.encode(targetDays, forKey: .targetDays)
        try c.encode(currentCount, forKey: .currentCount)
        try c.encodeIfPresent(lastCompletedDate, forKey: .lastCompletedDate)
        try c.encodeIfPresent(senderName, forKey: .senderName)
        try c.encodeIfPresent(senderEmoji, forKey: .senderEmoji)
        try c.encode(senderTotalCompletedCount, forKey: .senderTotalCompletedCount)
        try c.encodeIfPresent(completionImageURL, forKey: .completionImageURL)
        try c.encodeIfPresent(createdByUserId, forKey: .createdByUserId)
        try c.encodeIfPresent(createdByUserName, forKey: .createdByUserName)
    }
    
    let id: String
    var title: String
    var description: String?
    var epicId: String? // エピックに属する場合
    var status: TaskStatus
    var verificationMode: VerificationMode
    var priority: TaskPriority
    var dueDate: Date?
    var completedDate: Date?
    var photoEvidenceURL: String? // 写真証拠のURL（Firebase Storage）
    var createdAt: Date
    var updatedAt: Date
    var xpReward: Int // 完了時のXP報酬
    var rewardDisplayName: String? // 達成時に解禁したい報酬名（Giftの内容）
    var isRoutine: Bool // 毎日ルーチンタスクかどうか
    var senderId: String? // 届いたタスクの場合の送り主UID
    var fromDisplayName: String? // 送り主の表示名（後方互換）
    var senderName: String? // 送り主の表示名（優先）
    var senderEmoji: String? // 送り主の絵文字アイコン
    var senderTotalCompletedCount: Int // 送り主の累計達成数（0=非届きタスク）
    var completionImageURL: String? // 完了報告画像（Firebase Storage URL）
    var createdByUserId: String? // 作成者UID
    var createdByUserName: String? // 作成者表示名
    var rewardId: String? // 届いたタスクの場合の紐づくギフトID（完了時にFirestore更新用）
    var targetDays: Int // 目標達成に必要な合計日数（累計達成型、デフォルト1で単発）
    var currentCount: Int // これまでに完了した累計日数
    var lastCompletedDate: Date? // 最後に完了した日付（復活判定用）
    
    // 初期化
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        epicId: String? = nil,
        status: TaskStatus = .pending,
        verificationMode: VerificationMode = .selfDeclaration,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        completedDate: Date? = nil,
        photoEvidenceURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        xpReward: Int = 10,
        rewardDisplayName: String? = nil,
        isRoutine: Bool = false,
        senderId: String? = nil,
        fromDisplayName: String? = nil,
        rewardId: String? = nil,
        targetDays: Int = 1,
        currentCount: Int = 0,
        lastCompletedDate: Date? = nil,
        senderName: String? = nil,
        senderEmoji: String? = nil,
        senderTotalCompletedCount: Int = 0,
        completionImageURL: String? = nil,
        createdByUserId: String? = nil,
        createdByUserName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.epicId = epicId
        self.status = status
        self.verificationMode = verificationMode
        self.priority = priority
        self.dueDate = dueDate
        self.completedDate = completedDate
        self.photoEvidenceURL = photoEvidenceURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.xpReward = xpReward
        self.rewardDisplayName = rewardDisplayName
        self.isRoutine = isRoutine
        self.senderId = senderId
        self.fromDisplayName = fromDisplayName
        self.rewardId = rewardId
        self.targetDays = targetDays
        self.currentCount = currentCount
        self.lastCompletedDate = lastCompletedDate
        self.senderName = senderName
        self.senderEmoji = senderEmoji
        self.senderTotalCompletedCount = senderTotalCompletedCount
        self.completionImageURL = completionImageURL
        self.createdByUserId = createdByUserId
        self.createdByUserName = createdByUserName
    }
    
    /// 目標日数制かどうか（1より大きい場合）
    var isTargetDaysTask: Bool { targetDays > 1 }
    
    /// 残り日数（目標まであと何日）
    var remainingDays: Int { max(0, targetDays - currentCount) }
    
    // 完了処理（currentCount +1、lastCompletedDate 更新。targetDays に達した時のみ status = .completed）
    mutating func complete(with photoURL: String? = nil) {
        let now = Date()
        currentCount += 1
        lastCompletedDate = now
        completedDate = now
        photoEvidenceURL = photoURL
        updatedAt = now
        if currentCount >= targetDays {
            status = .completed
        } else {
            // 累計途中：一旦 completed にし、復活ロジックで翌日以降 active に戻す
            status = .completed
        }
    }
}

// MARK: - Task Status
enum TaskStatus: String, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case archived = "archived"
    /// 受信者が完了報告済み・送信者の承認待ち
    case pendingApproval = "pending_approval"
}

// MARK: - Verification Mode
enum VerificationMode: String, Codable {
    case selfDeclaration = "self_declaration" // タップ: 自己申告
    case photoEvidence = "photo_evidence"     // 長押し: 写真証拠
}

// MARK: - Task Priority
enum TaskPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .urgent: return "緊急"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "blue"
        case .medium: return "green"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

