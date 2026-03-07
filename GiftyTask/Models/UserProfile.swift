import Foundation

// MARK: - UserProfile（Firestore users コレクション用）
/// ユーザープロフィール（uid, display_name, avatar_emoji, friend_list, total_completed_count）
struct UserProfile: Codable {
    var uid: String
    var displayName: String
    var avatarEmoji: String
    var friendList: [String]
    var totalCompletedCount: Int
    
    enum CodingKeys: String, CodingKey {
        case uid
        case displayName = "display_name"
        case avatarEmoji = "avatar_emoji"
        case friendList = "friend_list"
        case totalCompletedCount = "total_completed_count"
    }
    
    init(uid: String, displayName: String, avatarEmoji: String = "👤", friendList: [String] = [], totalCompletedCount: Int = 0) {
        self.uid = uid
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.friendList = friendList
        self.totalCompletedCount = totalCompletedCount
    }
}
