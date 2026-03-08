import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import Combine

// MARK: - Auth Manager
/// 匿名ログインと Firestore ユーザープロフィールの作成・保存
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let usersCollection = "users"
    
    private static func displayNameKey(uid: String) -> String { "gifty_display_name_\(uid)" }
    
    /// 現在のユーザー（ログイン済み）
    @Published private(set) var currentUser: FirebaseAuth.User?
    
    /// Firestore のユーザープロフィール
    @Published private(set) var userProfile: UserProfile?
    
    /// 認証状態（ローディング中）
    @Published private(set) var isLoading = false
    
    /// エラーメッセージ
    @Published var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var fcmTokenObserver: NSObjectProtocol?
    
    private init() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            _Concurrency.Task { @MainActor in
                self?.currentUser = user
                if let uid = user?.uid {
                    await self?.fetchUserProfile(uid: uid)
                    await self?.refreshFCMTokenIfNeeded()
                } else {
                    self?.userProfile = nil
                }
            }
        }
        fcmTokenObserver = NotificationCenter.default.addObserver(forName: .fcmTokenDidUpdate, object: nil, queue: .main) { [weak self] note in
            guard let token = note.userInfo?["token"] as? String, !token.isEmpty else { return }
            _Concurrency.Task { @MainActor in
                await self?.saveFCMToken(token)
            }
        }
    }
    
    deinit {
        if let handle = authStateListener {
            auth.removeStateDidChangeListener(handle)
        }
        if let o = fcmTokenObserver {
            NotificationCenter.default.removeObserver(o)
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
    func createOrUpdateUserProfile(
        uid: String,
        displayName: String,
        avatarEmoji: String = "👤",
        friendList: [String] = [],
        totalCompletedCount: Int? = nil,
        fcmToken: String? = nil
    ) async throws {
        let current = userProfile
        let count = totalCompletedCount ?? current?.totalCompletedCount ?? 0
        let token = fcmToken ?? current?.fcmToken
        let profile = UserProfile(
            uid: uid,
            displayName: displayName,
            avatarEmoji: avatarEmoji,
            friendList: friendList,
            totalCompletedCount: count,
            fcmToken: token
        )
        var data: [String: Any] = [
            "uid": profile.uid,
            "display_name": profile.displayName,
            "avatar_emoji": profile.avatarEmoji,
            "friend_list": profile.friendList,
            "total_completed_count": profile.totalCompletedCount
        ]
        if let t = token, !t.isEmpty {
            data["fcm_token"] = t
        }
        let ref = db.collection(usersCollection).document(uid)
        try await setDataAsync(ref: ref, data: data)
        userProfile = profile
        UserDefaults.standard.set(displayName, forKey: Self.displayNameKey(uid: uid))
        objectWillChange.send()
    }
    
    /// FCM トークンを Firestore に保存（ログイン中のみ）
    func saveFCMToken(_ token: String) async {
        guard let uid = currentUser?.uid, !token.isEmpty else { return }
        do {
            let ref = db.collection(usersCollection).document(uid)
            try await setDataAsync(ref: ref, data: ["fcm_token": token])
            if var p = userProfile {
                p.fcmToken = token
                userProfile = p
                objectWillChange.send()
            }
        } catch {
            print("saveFCMToken error: \(error)")
        }
    }
    
    /// プロフィール取得後に FCM トークンを取得して保存
    private func refreshFCMTokenIfNeeded() async {
        let token = await Messaging.messaging().token()
        if let t = token, !t.isEmpty {
            await saveFCMToken(t)
        }
    }
    
    /// 他ユーザーのプロフィールを取得（表示名表示用、Firestoreルールで read 許可が必要）
    func fetchOtherUserProfile(uid: String) async -> UserProfile? {
        do {
            let ref = db.collection(usersCollection).document(uid)
            let doc = try await getDocumentAsync(ref: ref)
            guard doc.exists, let data = doc.data() else { return nil }
            let displayName = data["display_name"] as? String ?? "ユーザー"
            let avatarEmoji = data["avatar_emoji"] as? String ?? "👤"
            let friendList = data["friend_list"] as? [String] ?? []
            let totalCompletedCount = data["total_completed_count"] as? Int ?? 0
            let fcmToken = data["fcm_token"] as? String
            return UserProfile(
                uid: uid,
                displayName: displayName,
                avatarEmoji: avatarEmoji,
                friendList: friendList,
                totalCompletedCount: totalCompletedCount,
                fcmToken: fcmToken
            )
        } catch {
            return nil
        }
    }
    
    /// Firestore からユーザープロフィールを取得（自分のプロフィール用）
    func fetchUserProfile(uid: String) async {
        let cachedDisplayName = UserDefaults.standard.string(forKey: Self.displayNameKey(uid: uid))
        do {
            let ref = db.collection(usersCollection).document(uid)
            let doc = try await getDocumentAsync(ref: ref)
            if doc.exists, let data = doc.data() {
                let displayName = data["display_name"] as? String ?? cachedDisplayName ?? "ユーザー"
                let avatarEmoji = data["avatar_emoji"] as? String ?? "👤"
                let friendList = data["friend_list"] as? [String] ?? []
                let totalCompletedCount = data["total_completed_count"] as? Int ?? 0
                let fcmToken = data["fcm_token"] as? String
                userProfile = UserProfile(
                    uid: uid,
                    displayName: displayName,
                    avatarEmoji: avatarEmoji,
                    friendList: friendList,
                    totalCompletedCount: totalCompletedCount,
                    fcmToken: fcmToken
                )
                UserDefaults.standard.set(displayName, forKey: Self.displayNameKey(uid: uid))
            } else {
                let initialName = cachedDisplayName ?? "ユーザー"
                try await createOrUpdateUserProfile(uid: uid, displayName: initialName)
            }
        } catch {
            if let cached = cachedDisplayName {
                userProfile = UserProfile(
                    uid: uid,
                    displayName: cached,
                    avatarEmoji: "👤",
                    friendList: [],
                    totalCompletedCount: 0
                )
            } else {
                errorMessage = "プロフィール取得に失敗: \(error.localizedDescription)"
            }
        }
    }
    
    /// プロフィールを更新（表示名・絵文字）
    func updateProfile(displayName: String, avatarEmoji: String) async throws {
        guard let uid = currentUser?.uid else { return }
        try await createOrUpdateUserProfile(
            uid: uid,
            displayName: displayName,
            avatarEmoji: avatarEmoji,
            friendList: userProfile?.friendList ?? [],
            totalCompletedCount: userProfile?.totalCompletedCount ?? 0
        )
    }
    
    /// フレンドを追加（重複チェック）
    func addFriend(_ uid: String) async throws {
        guard let me = currentUser?.uid, uid != me else { return }
        var list = userProfile?.friendList ?? []
        if !list.contains(uid) {
            list.append(uid)
            try await createOrUpdateUserProfile(
                uid: me,
                displayName: userProfile?.displayName ?? "ユーザー",
                avatarEmoji: userProfile?.avatarEmoji ?? "👤",
                friendList: list,
                totalCompletedCount: userProfile?.totalCompletedCount ?? 0
            )
        }
    }
    
    /// 累計達成数を +1
    func incrementTotalCompletedCount() async {
        guard let uid = currentUser?.uid else { return }
        let current = (userProfile?.totalCompletedCount ?? 0) + 1
        do {
            let ref = db.collection(usersCollection).document(uid)
            try await setDataAsync(ref: ref, data: [
                "total_completed_count": current
            ])
            var p = userProfile ?? UserProfile(uid: uid, displayName: "ユーザー")
            p.totalCompletedCount = current
            userProfile = p
            objectWillChange.send()
        } catch {
            print("incrementTotalCompletedCount error: \(error)")
        }
    }
    
    // MARK: - Firestore 非同期ヘルパー（continuation を分離して型推論・Decoder 誤解を防止）
    
    private func setDataAsync(ref: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.setData(data, merge: true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func getDocumentAsync(ref: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<DocumentSnapshot, Error>) in
            ref.getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"]))
                }
            }
        }
    }
    
    // MARK: - ログアウト
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        userProfile = nil
    }
}
