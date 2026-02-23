import Foundation

// MARK: - UserProfile（Firestore users コレクション用）
/// ユーザープロフィール（uid, display_name, friend_list）
struct UserProfile: Codable {
    /// Firebase Auth UID（ドキュメントIDと一致）
    var uid: String
    var displayName: String
    var friendList: [String]
    
    enum CodingKeys: String, CodingKey {
        case uid
        case displayName = "display_name"
        case friendList = "friend_list"
    }
    
    init(uid: String, displayName: String, friendList: [String] = []) {
        self.uid = uid
        self.displayName = displayName
        self.friendList = friendList
    }
}
