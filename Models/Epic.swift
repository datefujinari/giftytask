import Foundation

// MARK: - Epic Model
struct Epic: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var description: String?
    var status: EpicStatus
    var giftId: String? // 関連するギフトID
    var taskIds: [String] // 子タスクIDのリスト
    var startDate: Date
    var targetDate: Date?
    var completedDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    // 計算プロパティ
    var progress: Double {
        // 実際の完了率はViewModelで計算
        // ここでは基本構造のみ
        return 0.0
    }
    
    // 初期化
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        status: EpicStatus = .active,
        giftId: String? = nil,
        taskIds: [String] = [],
        startDate: Date = Date(),
        targetDate: Date? = nil,
        completedDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.giftId = giftId
        self.taskIds = taskIds
        self.startDate = startDate
        self.targetDate = targetDate
        self.completedDate = completedDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // 完了処理
    mutating func complete() {
        self.status = .completed
        self.completedDate = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Epic Status
enum EpicStatus: String, Codable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case archived = "archived"
}

