import Foundation

// MARK: - Routine Model
struct Routine: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    /// 紐付くギフトのID（Gift.id と同一の文字列）
    var associatedGiftId: String
    /// ギフト獲得に必要な累積達成回数（同一サイクル内の完了日数）
    var targetCount: Int
    /// 現在のサイクルでの達成回数（ギフト獲得でリセット）
    var currentCycleCount: Int
    var order: Int
    var completionHistory: [String] // ISO 8601形式の日付文字列（YYYY-MM-DD）
    
    /// 今日の日付がcompletionHistoryに含まれているか
    var isCompletedToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let todayString = formatter.string(from: Date())
        return completionHistory.contains(todayString)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        associatedGiftId: String = "",
        targetCount: Int = 7,
        currentCycleCount: Int = 0,
        order: Int = 0,
        completionHistory: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.associatedGiftId = associatedGiftId
        self.targetCount = max(1, targetCount)
        self.currentCycleCount = max(0, currentCycleCount)
        self.order = order
        self.completionHistory = completionHistory
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, order, completionHistory
        case associatedGiftId = "associated_gift_id"
        case targetCount = "target_count"
        case currentCycleCount = "current_cycle_count"
        case points // 旧データ用（デコードのみ）
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
        completionHistory = try c.decodeIfPresent([String].self, forKey: .completionHistory) ?? []
        
        if let gid = try c.decodeIfPresent(String.self, forKey: .associatedGiftId), !gid.isEmpty {
            associatedGiftId = gid
        } else {
            associatedGiftId = ""
        }
        if let tc = try c.decodeIfPresent(Int.self, forKey: .targetCount) {
            targetCount = max(1, tc)
        } else {
            targetCount = 7
        }
        currentCycleCount = max(0, try c.decodeIfPresent(Int.self, forKey: .currentCycleCount) ?? 0)
        _ = try c.decodeIfPresent(Int.self, forKey: .points) // 旧フィールドを読み捨て
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encode(order, forKey: .order)
        try c.encode(completionHistory, forKey: .completionHistory)
        try c.encode(associatedGiftId, forKey: .associatedGiftId)
        try c.encode(targetCount, forKey: .targetCount)
        try c.encode(currentCycleCount, forKey: .currentCycleCount)
    }
}
