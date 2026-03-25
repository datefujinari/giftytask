import Foundation
import UserNotifications
import FirebaseMessaging

// MARK: - 通知（ローカル通知中心。相手端末へのプッシュは Cloud Functions / FCM サーバーが必要）
@MainActor
enum NotificationService {
    
    // MARK: - 共通: ローカル通知（権限があれば必ずキュー）
    static func enqueueLocalNotification(title: String, body: String) {
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
    
    /// 他ユーザーからタスクを受信したとき（受信者の端末）
    static func notifyIncomingTask(senderName: String, taskTitle: String) {
        enqueueLocalNotification(
            title: "新着タスク",
            body: "\(senderName)さんから「\(taskTitle)」が届きました"
        )
    }
    
    /// ルーティン提案を受信したとき（受信者の端末）
    static func notifyIncomingRoutineSuggestion(senderName: String, routineTitle: String) {
        enqueueLocalNotification(
            title: "ルーティン提案",
            body: "\(senderName)さんから「\(routineTitle)」の提案が届きました"
        )
    }
    
    /// 完了報告を送信した直後（報告した本人の端末）
    static func notifyCompletionReportSubmitted() {
        enqueueLocalNotification(
            title: "完了報告を送信しました",
            body: "相手の承認をお待ちください。"
        )
    }
    
    /// 相手から完了報告が届いたとき（タスク作成者＝送信者の端末）
    static func notifyCompletionReportReceived(receiverName: String, taskTitle: String) {
        enqueueLocalNotification(
            title: "完了報告",
            body: "\(receiverName)さんが「\(taskTitle)」の完了報告を送りました。承認してください。"
        )
    }
    
    /// タスクが承認されギフトが受け取れる状態になったとき（受信者の端末）
    static func notifyTaskApprovedGiftUnlocked(taskTitle: String, giftName: String) {
        enqueueLocalNotification(
            title: "ギフトが解放されました",
            body: "「\(taskTitle)」が承認されました。「\(giftName)」をギフトBOXで確認できます。"
        )
    }
    
    /// 届いていたタスクが Firestore 上から削除されたとき（受信者の端末）
    static func notifyReceivedTaskRemoved(taskTitle: String) {
        enqueueLocalNotification(
            title: "タスクが取り消されました",
            body: "「\(taskTitle)」は送信者により削除されました。"
        )
    }
    
    /// 送信したタスクが Firestore から消えたとき（作成者＝送信者の端末）
    static func notifySentTaskRemovedAsCreator(taskTitle: String) {
        enqueueLocalNotification(
            title: "タスクが削除されました",
            body: "「\(taskTitle)」のデータが削除されました。"
        )
    }
    
    /// ギフトを「使う」で受け取ったとき（使った本人の端末）
    /// 作成者へ「相手が受け取った」通知は別端末のため Cloud Functions + FCM が必要
    static func notifyGiftRedeemedLocally(giftTitle: String) {
        enqueueLocalNotification(
            title: "ギフトを受け取りました",
            body: "「\(giftTitle)」を受け取りました。"
        )
    }
    
    /// ルーティン達成でギフトが解放されたとき（本人の端末）
    static func notifyRoutineGiftUnlocked(giftTitle: String, routineTitle: String) {
        enqueueLocalNotification(
            title: "ルーティン達成！",
            body: "「\(routineTitle)」の目標を達成し「\(giftTitle)」が解放されました。"
        )
    }
    
    // MARK: - 互換: 旧API（FCM トークンは参照のみ。ローカル通知は常に出す）
    
    /// タスク受信時: 受信者へ
    static func notifyTaskReceived(receiverFCMToken: String?, senderDisplayName: String) {
        _ = receiverFCMToken
        enqueueLocalNotification(
            title: "新着タスク",
            body: "\(senderDisplayName)さんからタスクが届きました"
        )
    }
    
    /// 受け入れ/拒否時: 送信者へ
    static func notifyTaskAccepted(senderFCMToken: String?, receiverDisplayName: String, accepted: Bool) {
        _ = senderFCMToken
        let body = accepted
            ? "\(receiverDisplayName)さんがタスクを承認しました"
            : "\(receiverDisplayName)さんがタスクを拒否しました"
        enqueueLocalNotification(title: "タスクの承認", body: body)
    }
    
    /// タスク完了報告時: 送信者へ（旧名のまま。実際は sentTasks リスナー側で通知推奨）
    static func notifyTaskCompletionReported(senderFCMToken: String?, receiverDisplayName: String) {
        _ = senderFCMToken
        enqueueLocalNotification(
            title: "完了報告",
            body: "\(receiverDisplayName)さんがタスクを完了しました。承認してください。"
        )
    }
    
    /// テスト用
    static func scheduleTestNotification(delaySeconds: TimeInterval = 5) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("[NotificationService] authorizationStatus = \(settings.authorizationStatus.rawValue)")
        }
        let content = UNMutableNotificationContent()
        content.title = "テスト通知"
        content.body = "\(Int(delaySeconds))秒後に届くテストです。"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "test_notification_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: delaySeconds, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("テスト通知スケジュール失敗: \(error.localizedDescription)")
            }
        }
    }
}
