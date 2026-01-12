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
        updatedAt: Date = Date()
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
    }
    
    // アンロック処理
    mutating func unlock(with giftURL: String, gifteeGiftId: String) {
        self.status = .unlocked
        self.giftURL = giftURL
        self.gifteeGiftId = gifteeGiftId
        self.unlockedAt = Date()
        self.updatedAt = Date()
    }
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

// MARK: - Unlock Condition
struct UnlockCondition: Codable, Hashable {
    var conditionType: ConditionType
    var epicId: String? // エピック完了の場合
    var taskId: String? // タスク完了の場合
    var xpThreshold: Int? // XP閾値の場合
    var streakDays: Int? // 連続日数の場合
    
    enum ConditionType: String, Codable {
        case epicCompletion = "epic_completion"
        case taskCompletion = "task_completion"
        case xpThreshold = "xp_threshold"
        case streakDays = "streak_days"
    }
}

