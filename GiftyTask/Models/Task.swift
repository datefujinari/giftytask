import Foundation

// MARK: - Task Model
struct Task: Identifiable, Codable, Hashable {
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
        isRoutine: Bool = false
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
    }
    
    // 完了処理
    mutating func complete(with photoURL: String? = nil) {
        self.status = .completed
        self.completedDate = Date()
        self.photoEvidenceURL = photoURL
        self.updatedAt = Date()
    }
}

// MARK: - Task Status
enum TaskStatus: String, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case archived = "archived"
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

