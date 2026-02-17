import Foundation

// MARK: - Gift Model
struct Gift: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var description: String?
    var giftURL: String? // giftee APIから取得したギフトURL（アンロック時のみ）
    var status: GiftStatus
    var type: GiftType
    var unlockCondition: UnlockCondition
    var epicId: String? // エピックに関連する場合
    var taskId: String? // 単一タスクに関連する場合
    var assignedToUserId: String? // ソーシャル機能: 割り当て先ユーザーID
    var assignedFromUserId: String? // ソーシャル機能: 割り当て元ユーザーID
    var price: Double // 価格（円）
    var currency: String // 通貨コード（JPY）
    var gifteeGiftId: String? // giftee APIのギフトID
    var unlockedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var rewardUrl: String?
    var currentStreak: Int
    
    // 初期化
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        giftURL: String? = nil,
        status: GiftStatus = .locked,
        type: GiftType = .selfReward,
        unlockCondition: UnlockCondition,
        epicId: String? = nil,
        taskId: String? = nil,
        assignedToUserId: String? = nil,
        assignedFromUserId: String? = nil,
        price: Double,
        currency: String = "JPY",
        gifteeGiftId: String? = nil,
        unlockedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        rewardUrl: String? = nil,
        currentStreak: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.giftURL = giftURL
        self.status = status
        self.type = type
        self.unlockCondition = unlockCondition
        self.epicId = epicId
        self.taskId = taskId
        self.assignedToUserId = assignedToUserId
        self.assignedFromUserId = assignedFromUserId
        self.price = price
        self.currency = currency
        self.gifteeGiftId = gifteeGiftId
        self.unlockedAt = unlockedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rewardUrl = rewardUrl
        self.currentStreak = currentStreak
    }
    
    var effectiveRewardUrl: String? { rewardUrl ?? giftURL }
    
    /// ロック状態（status の簡易アクセス）
    var isLocked: Bool { status == .locked }
    
    /// アンロック処理（URL付き・外部連携用）
    mutating func unlock(with giftURL: String, gifteeGiftId: String) {
        self.status = .unlocked
        self.giftURL = giftURL
        self.gifteeGiftId = gifteeGiftId
        self.unlockedAt = Date()
        self.updatedAt = Date()
    }
    
    /// 条件達成時のアンロック（rewardUrl があれば設定、なければおめでとうモーダル用）
    mutating func unlockLocally(rewardURL: String? = nil) {
        self.status = .unlocked
        self.giftURL = rewardURL ?? rewardUrl ?? Gift.defaultGiftURL
        self.unlockedAt = Date()
        self.updatedAt = Date()
    }
    
    static let defaultGiftURL = "https://linegift.line.me/"
}

// MARK: - Gift Status
enum GiftStatus: String, Codable {
    case locked = "locked"       // ロック済み（半透明表示）
    case unlocked = "unlocked"   // アンロック済み（ギフトURL利用可能）
    case redeemed = "redeemed"   // 引き換え済み
}

// MARK: - Gift Type
enum GiftType: String, Codable {
    case selfReward = "self_reward"        // 自己報酬
    case friendAssigned = "friend_assigned" // フレンドから割り当て
}

// MARK: - Unlock Condition（targetIds でエピック/タスクIDを統一管理）
struct UnlockCondition: Codable, Hashable {
    var conditionType: ConditionType
    /// 対象ID（エピック1つ / タスク1つ / タスク複数 / 継続用タスク1つ）
    var targetIds: [String]
    var epicId: String? { conditionType == .epicCompletion ? targetIds.first : nil }
    var taskId: String? { (conditionType == .singleTask || conditionType == .streak) ? targetIds.first : nil }
    var taskIds: [String]? { conditionType == .multipleTasks ? targetIds : nil }
    var xpThreshold: Int?
    /// 継続必要日数（streak の場合）
    var streakDays: Int?
    
    enum ConditionType: String, Codable, CaseIterable {
        case epicCompletion = "epic_completion"
        case singleTask = "single_task"
        case multipleTasks = "multiple_tasks"
        case streak = "streak"
        case xpThreshold = "xp_threshold"
        case taskCompletion = "task_completion"     // 旧: singleTask にマッピング
        case multipleTasksCompletion = "multiple_tasks_completion"
        case streakDays = "streak_days"            // 旧: streak にマッピング
    }
    
    static func displayName(for type: ConditionType) -> String {
        switch type {
        case .epicCompletion: return "エピック完了"
        case .singleTask, .taskCompletion: return "特定タスク完了"
        case .multipleTasks, .multipleTasksCompletion: return "複数タスク完了"
        case .streak, .streakDays: return "継続達成"
        case .xpThreshold: return "XP閾値達成時"
        }
    }
    
    init(conditionType: ConditionType, targetIds: [String] = [], streakDays: Int? = nil, xpThreshold: Int? = nil) {
        self.conditionType = conditionType
        self.targetIds = targetIds
        self.streakDays = streakDays
        self.xpThreshold = xpThreshold
    }
    
    /// 後方互換：既存の epicId/taskId/taskIds から初期化
    init(conditionType: ConditionType, epicId: String? = nil, taskId: String? = nil, taskIds: [String]? = nil, streakDays: Int? = nil, xpThreshold: Int? = nil) {
        self.conditionType = conditionType
        self.streakDays = streakDays
        self.xpThreshold = xpThreshold
        switch conditionType {
        case .epicCompletion: self.targetIds = [epicId].compactMap { $0 }
        case .singleTask, .taskCompletion: self.targetIds = [taskId].compactMap { $0 }
        case .multipleTasks, .multipleTasksCompletion: self.targetIds = taskIds ?? []
        case .streak, .streakDays: self.targetIds = [taskId].compactMap { $0 }
        case .xpThreshold: self.targetIds = []
        }
    }
}

// 後方互換のため Decodable で epicId/taskId/taskIds も読む
extension UnlockCondition {
    enum CodingKeys: String, CodingKey {
        case conditionType, targetIds, streakDays, xpThreshold
        case epicId, taskId, taskIds
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        conditionType = try c.decode(ConditionType.self, forKey: .conditionType)
        streakDays = try c.decodeIfPresent(Int.self, forKey: .streakDays)
        xpThreshold = try c.decodeIfPresent(Int.self, forKey: .xpThreshold)
        if let ids = try c.decodeIfPresent([String].self, forKey: .targetIds) {
            targetIds = ids
        } else {
            let epicId = try c.decodeIfPresent(String.self, forKey: .epicId)
            let taskId = try c.decodeIfPresent(String.self, forKey: .taskId)
            let taskIds = try c.decodeIfPresent([String].self, forKey: .taskIds)
            switch conditionType {
            case .epicCompletion: targetIds = [epicId].compactMap { $0 }
            case .singleTask, .taskCompletion: targetIds = [taskId].compactMap { $0 }
            case .multipleTasks, .multipleTasksCompletion: targetIds = taskIds ?? []
            case .streak, .streakDays: targetIds = [taskId].compactMap { $0 }
            case .xpThreshold: targetIds = []
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(conditionType, forKey: .conditionType)
        try c.encode(targetIds, forKey: .targetIds)
        try c.encodeIfPresent(streakDays, forKey: .streakDays)
        try c.encodeIfPresent(xpThreshold, forKey: .xpThreshold)
    }
}

