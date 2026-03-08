import Foundation
import UserNotifications
import FirebaseMessaging

// MARK: - 通知送信ヘルパー（Cloud Functions 未使用時のアプリ内トリガー用）
/// 実際のプッシュ送信は FCM サーバーキーまたは Cloud Functions で行う想定。
/// ここでは送信タイミングのトリガーと、Cloud Functions 用のドキュメント更新のみ行う。
@MainActor
enum NotificationService {
    
    /// タスク受信時: 受信者へ「〇〇さんから新着タスクが届きました」
    static func notifyTaskReceived(receiverFCMToken: String?, senderDisplayName: String) {
        guard let token = receiverFCMToken, !token.isEmpty else { return }
        // Cloud Functions で onTaskCreated などにより送信するか、FCM REST API を呼ぶ
        enqueueLocalNotification(title: "新着タスク", body: "\(senderDisplayName)さんからタスクが届きました")
    }
    
    /// 受け入れ/拒否時: 送信者へ「〇〇さんがタスクを承認/拒否しました」
    static func notifyTaskAccepted(senderFCMToken: String?, receiverDisplayName: String, accepted: Bool) {
        guard let token = senderFCMToken, !token.isEmpty else { return }
        let body = accepted
            ? "\(receiverDisplayName)さんがタスクを承認しました"
            : "\(receiverDisplayName)さんがタスクを拒否しました"
        enqueueLocalNotification(title: "タスクの承認", body: body)
    }
    
    /// タスク完了報告時: 送信者へ「〇〇さんがタスクを完了しました！承認してください」
    static func notifyTaskCompletionReported(senderFCMToken: String?, receiverDisplayName: String) {
        guard let token = senderFCMToken, !token.isEmpty else { return }
        enqueueLocalNotification(
            title: "完了報告",
            body: "\(receiverDisplayName)さんがタスクを完了しました。承認してください。"
        )
    }
    
    /// ローカル通知（プッシュ未設定時のお知らせ）
    private static func enqueueLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
