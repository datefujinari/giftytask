import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

// MARK: - App Delegate（FCM・プッシュ通知）
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        requestNotificationPermission(application: application)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("FCM: APNs registration failed: \(error.localizedDescription)")
    }
    
    private func requestNotificationPermission(application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("FCM: Notification permission error: \(error.localizedDescription)")
                return
            }
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    // MARK: - MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let token = fcmToken ?? ""
        if token.isEmpty {
            print("FCM: token is empty")
            return
        }
        print("FCM token: \(token.prefix(20))...")
        NotificationCenter.default.post(
            name: .fcmTokenDidUpdate,
            object: nil,
            userInfo: ["token": token]
        )
    }
    
    // MARK: - UNUserNotificationCenterDelegate（フォアグラウンドで通知表示）
    /// Cloud Functions 経由のプッシュは `gifty_cf` を付与。アプリ起動中は Firestore リスナーでローカル通知済みのため二重表示を防ぐ。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let flag = userInfo["gifty_cf"] as? String, flag == "1" {
            completionHandler([])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }
}

extension Notification.Name {
    static let fcmTokenDidUpdate = Notification.Name("fcmTokenDidUpdate")
}
