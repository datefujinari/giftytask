import Foundation

// MARK: - User Model
struct User: Identifiable, Codable, Hashable {
    let id: String // Firebase Auth UID
    var displayName: String
    var email: String?
    var photoURL: String?
    var level: Int
    var xp: Int
    var totalXP: Int // 累積XP
    var currentTheme: String // 現在のテーマ（レベル別アンロック）
    var unlockedThemes: [String] // アンロック済みテーマリスト
    var unlockedBadges: [String] // アンロック済みバッジリスト
    var createdAt: Date
    var updatedAt: Date
    
    // 計算プロパティ: 次のレベルまでのXP
    var xpToNextLevel: Int {
        levelXPRequired(for: level + 1) - totalXP
    }
    
    // レベルに必要なXPを計算
    func levelXPRequired(for level: Int) -> Int {
        // 例: レベルNには N * 100 XPが必要
        return level * 100
    }
    
    // 初期化
    init(
        id: String,
        displayName: String,
        email: String? = nil,
        photoURL: String? = nil,
        level: Int = 1,
        xp: Int = 0,
        totalXP: Int = 0,
        currentTheme: String = "default",
        unlockedThemes: [String] = ["default"],
        unlockedBadges: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.photoURL = photoURL
        self.level = level
        self.xp = xp
        self.totalXP = totalXP
        self.currentTheme = currentTheme
        self.unlockedThemes = unlockedThemes
        self.unlockedBadges = unlockedBadges
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // XP追加（レベルアップチェック含む）
    mutating func addXP(_ amount: Int) -> Bool {
        // レベルアップしたかどうか
        let oldLevel = level
        totalXP += amount
        xp += amount
        
        // レベルアップ判定
        while totalXP >= levelXPRequired(for: level + 1) {
            level += 1
            // レベルアップ時のテーマアンロック等の処理はViewModelで行う
        }
        
        updatedAt = Date()
        return level > oldLevel
    }
}

// MARK: - Friendship Model
struct Friendship: Identifiable, Codable, Hashable {
    let id: String
    var userId1: String // ユーザー1のID
    var userId2: String // ユーザー2のID
    var status: FriendshipStatus
    var requestedBy: String // リクエストしたユーザーID
    var acceptedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    enum FriendshipStatus: String, Codable {
        case pending = "pending"       // リクエスト待ち
        case accepted = "accepted"     // 承認済み
        case blocked = "blocked"       // ブロック済み
    }
    
    init(
        id: String = UUID().uuidString,
        userId1: String,
        userId2: String,
        status: FriendshipStatus = .pending,
        requestedBy: String,
        acceptedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId1 = userId1
        self.userId2 = userId2
        self.status = status
        self.requestedBy = requestedBy
        self.acceptedAt = acceptedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

