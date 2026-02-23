import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// MARK: - Auth Manager
/// 匿名ログインと Firestore ユーザープロフィールの作成・保存
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    /// 現在のユーザー（ログイン済み）
    @Published private(set) var currentUser: FirebaseAuth.User?
    
    /// Firestore のユーザープロフィール
    @Published private(set) var userProfile: UserProfile?
    
    /// 認証状態（ローディング中）
    @Published private(set) var isLoading = false
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let uid = user?.uid {
                    await self?.fetchUserProfile(uid: uid)
                } else {
                    self?.userProfile = nil
                }
            }
        }
    }
    
    deinit {
        if let handle = authStateListener {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - 匿名ログイン
    
    /// 匿名ログイン（後でメール/Apple等に連携可能）
    func signInAnonymously() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let result = try await auth.signInAnonymously()
        let uid = result.user.uid
        let displayName = "ユーザー" // 初期表示名
        
        // Firestore にユーザープロフィールを作成
        try await createOrUpdateUserProfile(uid: uid, displayName: displayName)
    }
    
    // MARK: - ユーザープロフィール（Firestore）
    
    /// ユーザープロフィールを作成または更新
    func createOrUpdateUserProfile(uid: String, displayName: String, friendList: [String] = []) async throws {
        let profile = UserProfile(uid: uid, displayName: displayName, friendList: friendList)
        
        let data: [String: Any] = [
            "uid": profile.uid,
            "display_name": profile.displayName,
            "friend_list": profile.friendList
        ]
        
        try db.collection(usersCollection).document(uid).setData(data, merge: true)
        self.userProfile = profile
    }
    
    /// Firestore からユーザープロフィールを取得
    func fetchUserProfile(uid: String) async {
        do {
            let doc = try await db.collection(usersCollection).document(uid).getDocument()
            if doc.exists, let data = doc.data() {
                let displayName = data["display_name"] as? String ?? "ユーザー"
                let friendList = data["friend_list"] as? [String] ?? []
                userProfile = UserProfile(uid: uid, displayName: displayName, friendList: friendList)
            } else {
                // ドキュメントがなければ作成（fetchUserProfile は呼び出し元が MainActor を想定）
                try await createOrUpdateUserProfile(uid: uid, displayName: "ユーザー")
            }
        } catch {
            errorMessage = "プロフィール取得に失敗: \(error.localizedDescription)"
        }
    }
    
    /// プロフィールを更新（表示名など）
    func updateDisplayName(_ displayName: String) async throws {
        guard let uid = currentUser?.uid else { return }
        try await createOrUpdateUserProfile(
            uid: uid,
            displayName: displayName,
            friendList: userProfile?.friendList ?? []
        )
    }
    
    // MARK: - ログアウト
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        userProfile = nil
    }
}
