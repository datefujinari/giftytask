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
    
    /// アンロック処理（条件達成のみ・アプリ内表示用）
    mutating func unlockLocally() {
        self.status = .unlocked
        self.giftURL = Gift.defaultGiftURL
        self.unlockedAt = Date()
        self.updatedAt = Date()
    }
    
    /// アンロック後のデフォルト遷移先（LINEギフト公式など）
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

// MARK: - Unlock Condition
struct UnlockCondition: Codable, Hashable {
    var conditionType: ConditionType
    var epicId: String? // エピック完了の場合
    var taskId: String? // 単一タスク完了の場合
    var taskIds: [String]? // 複数タスク完了の場合
    var xpThreshold: Int? // XP閾値の場合
    var streakDays: Int? // 連続日数の場合
    
    enum ConditionType: String, Codable, CaseIterable {
        case epicCompletion = "epic_completion"
        case taskCompletion = "task_completion"
        case multipleTasksCompletion = "multiple_tasks_completion"
        case xpThreshold = "xp_threshold"
        case streakDays = "streak_days"
    }
    
    /// UI表示用のラベル
    static func displayName(for type: ConditionType) -> String {
        switch type {
        case .epicCompletion: return "健康習慣のエピック完了時"
        case .taskCompletion: return "特定のタスク完了時"
        case .multipleTasksCompletion: return "複数のタスク完了時"
        case .xpThreshold: return "XP閾値達成時"
        case .streakDays: return "タスクの継続達成時"
        }
    }
}

