import Foundation

// MARK: - UserProfile（Firestore users コレクション用）
/// ユーザープロフィール（uid, display_name, avatar_emoji, friend_list, total_completed_count, fcm_token）
struct UserProfile: Codable {
    var uid: String
    var displayName: String
    var avatarEmoji: String
    var friendList: [String]
    var totalCompletedCount: Int
    var fcmToken: String?
    
    enum CodingKeys: String, CodingKey {
        case uid
        case displayName = "display_name"
        case avatarEmoji = "avatar_emoji"
        case friendList = "friend_list"
        case totalCompletedCount = "total_completed_count"
        case fcmToken = "fcm_token"
    }
    
    init(uid: String, displayName: String, avatarEmoji: String = "👤", friendList: [String] = [], totalCompletedCount: Int = 0, fcmToken: String? = nil) {
        self.uid = uid
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.friendList = friendList
        self.totalCompletedCount = totalCompletedCount
        self.fcmToken = fcmToken
    }
}
