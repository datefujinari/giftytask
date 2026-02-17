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
    
    /// タスク完了時に updateGiftStatus を呼び、条件達成でアンロック
    func checkAndUnlockGifts(
        completedTask: Task,
        taskViewModel: TaskViewModel,
        activityViewModel: ActivityViewModel
    ) {
        updateGiftStatus(taskViewModel: taskViewModel, activityViewModel: activityViewModel, completedTask: completedTask)
    }
    
    /// ギフトのロック解除条件を評価。継続達成は1日途切れたら currentStreak リセット。
    func updateGiftStatus(
        taskViewModel: TaskViewModel,
        activityViewModel: ActivityViewModel,
        completedTask: Task? = nil
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for index in gifts.indices where gifts[index].status == .locked {
            var gift = gifts[index]
            let cond = gift.unlockCondition
            
            switch cond.conditionType {
            case .epicCompletion:
                guard let epicId = cond.targetIds.first else { continue }
                if isEpicFullyCompleted(epicId: epicId, taskViewModel: taskViewModel) {
                    unlockGiftAtIndex(index, gift: &gift)
                }
            case .singleTask, .taskCompletion:
                guard let taskId = cond.targetIds.first else { continue }
                if taskViewModel.tasks.first(where: { $0.id == taskId })?.status == .completed {
                    unlockGiftAtIndex(index, gift: &gift)
                }
            case .multipleTasks, .multipleTasksCompletion:
                guard !cond.targetIds.isEmpty else { continue }
                let allDone = cond.targetIds.allSatisfy { tid in
                    taskViewModel.tasks.first(where: { $0.id == tid })?.status == .completed
                }
                if allDone { unlockGiftAtIndex(index, gift: &gift) }
            case .streak, .streakDays:
                guard let routineTaskId = cond.targetIds.first,
                      let required = cond.streakDays else { continue }
                let routineTask = taskViewModel.tasks.first { $0.id == routineTaskId }
                let isRoutine = routineTask?.isRoutine == true
                if !isRoutine { continue }
                if let justCompleted = completedTask, justCompleted.id == routineTaskId {
                    gift.currentStreak += 1
                    if gift.currentStreak >= required {
                        unlockGiftAtIndex(index, gift: &gift)
                    } else {
                        gifts[index] = gift
                    }
                }
            case .xpThreshold:
                guard let threshold = cond.xpThreshold else { continue }
                if activityViewModel.currentUser.totalXP >= threshold {
                    unlockGiftAtIndex(index, gift: &gift)
                }
            }
        }
        
        resetStreaksIfDayBroken(calendar: calendar, today: today, taskViewModel: taskViewModel)
    }
    
    private func resetStreaksIfDayBroken(calendar: Calendar, today: Date, taskViewModel: TaskViewModel) {
        for index in gifts.indices {
            let cond = gifts[index].unlockCondition
            guard cond.conditionType == .streak || cond.conditionType == .streakDays,
                  let routineTaskId = cond.targetIds.first else { continue }
            let task = taskViewModel.tasks.first { $0.id == routineTaskId }
            guard task?.isRoutine == true else { continue }
            let lastCompleted = task?.completedDate.flatMap { calendar.startOfDay(for: $0) }
            if let last = lastCompleted {
                let daysSince = calendar.dateComponents([.day], from: last, to: today).day ?? 0
                if daysSince > 1 {
                    gifts[index].currentStreak = 0
                }
            }
        }
    }
    
    private func unlockGiftAtIndex(_ index: Int, gift: inout Gift) {
        gift.unlockLocally(rewardURL: gift.rewardUrl)
        gifts[index] = gift
        HapticManager.shared.giftUnlocked()
    }
    
    private func isEpicFullyCompleted(epicId: String, taskViewModel: TaskViewModel) -> Bool {
        let epicTasks = taskViewModel.getTasks(for: epicId)
        guard !epicTasks.isEmpty else { return false }
        return epicTasks.allSatisfy { $0.status == .completed }
    }
    
    func updateGift(_ gift: Gift) {
        guard let index = gifts.firstIndex(where: { $0.id == gift.id }) else { return }
        var updated = gift
        updated.updatedAt = Date()
        gifts[index] = updated
    }
    
    func loadGifts() {
        if gifts.isEmpty {
            gifts = PreviewContainer.mockGifts
        }
    }
}
