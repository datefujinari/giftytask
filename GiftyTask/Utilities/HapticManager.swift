import UIKit

// MARK: - Haptic Manager (Taptic Engine)
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// 軽いインパクトフィードバック
    func lightImpact() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// 中程度のインパクトフィードバック
    func mediumImpact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 重いインパクトフィードバック
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// 柔らかいインパクトフィードバック（iOS 13+）
    @available(iOS 13.0, *)
    func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// 硬いインパクトフィードバック（iOS 13+）
    @available(iOS 13.0, *)
    func rigidImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// 成功通知フィードバック
    func successNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 警告通知フィードバック
    func warningNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// エラー通知フィードバック
    func errorNotification() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// 選択フィードバック
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Task-specific Feedback
    
    /// タスク完了時のフィードバック（「パリン」という手応え: UINotificationFeedbackGenerator.success）
    func taskCompleted() {
        mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.successNotification() // .success で iOS 特有の「パリン」触覚
        }
    }
    
    /// ギフトアンロック時のフィードバック
    func giftUnlocked() {
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.successNotification()
        }
    }
    
    /// 長押し検出時のフィードバック
    func longPressDetected() {
        mediumImpact()
    }
    
    /// レベルアップ時のフィードバック
    func levelUp() {
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.successNotification()
        }
    }
}

