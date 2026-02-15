import Foundation
import Combine

// MARK: - Gift ViewModel
@MainActor
class GiftViewModel: ObservableObject {
    @Published var gifts: [Gift] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(gifts: [Gift] = []) {
        self.gifts = gifts.isEmpty ? PreviewContainer.mockGifts : gifts
    }
    
    /// ギフトを追加し、リストに即反映
    func addGift(_ gift: Gift) {
        gifts.append(gift)
    }
    
    /// ギフトを作成して追加
    func createGift(
        title: String,
        description: String? = nil,
        price: Double,
        unlockCondition: UnlockCondition,
        epicId: String? = nil,
        taskId: String? = nil
    ) -> Gift {
        let gift = Gift(
            title: title,
            description: description,
            status: .locked,
            type: .selfReward,
            unlockCondition: unlockCondition,
            epicId: epicId,
            taskId: taskId,
            price: price,
            currency: "JPY"
        )
        gifts.append(gift)
        return gift
    }
    
    /// タスク完了時に条件を評価し、満たしたギフトをアンロック
    func checkAndUnlockGifts(
        completedTask: Task,
        taskViewModel: TaskViewModel,
        activityViewModel: ActivityViewModel
    ) {
        for index in gifts.indices where gifts[index].status == .locked {
            if isConditionSatisfied(
                gift: gifts[index],
                completedTask: completedTask,
                taskViewModel: taskViewModel,
                activityViewModel: activityViewModel
            ) {
                gifts[index].unlockLocally()
                HapticManager.shared.giftUnlocked()
            }
        }
    }
    
    private func isConditionSatisfied(
        gift: Gift,
        completedTask: Task,
        taskViewModel: TaskViewModel,
        activityViewModel: ActivityViewModel
    ) -> Bool {
        let cond = gift.unlockCondition
        switch cond.conditionType {
        case .epicCompletion:
            guard let epicId = cond.epicId else { return false }
            return completedTask.epicId == epicId && isEpicFullyCompleted(epicId: epicId, taskViewModel: taskViewModel)
        case .taskCompletion:
            return cond.taskId == completedTask.id
        case .multipleTasksCompletion:
            guard let taskIds = cond.taskIds, !taskIds.isEmpty else { return false }
            return taskIds.allSatisfy { taskId in
                taskViewModel.tasks.first(where: { $0.id == taskId })?.status == .completed
            }
        case .streakDays:
            guard let required = cond.streakDays else { return false }
            return activityViewModel.streakData.currentStreak >= required
        case .xpThreshold:
            guard let threshold = cond.xpThreshold else { return false }
            return activityViewModel.currentUser.totalXP >= threshold
        }
    }
    
    private func isEpicFullyCompleted(epicId: String, taskViewModel: TaskViewModel) -> Bool {
        let epicTasks = taskViewModel.getTasks(for: epicId)
        guard !epicTasks.isEmpty else { return false }
        return epicTasks.allSatisfy { $0.status == .completed }
    }
    
    func loadGifts() {
        if gifts.isEmpty {
            gifts = PreviewContainer.mockGifts
        }
    }
}
