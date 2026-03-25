import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Task ViewModel
@MainActor
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var tasks: [Task] = []
    @Published var receivedTasks: [FirestoreTaskDTO] = [] // Firestore 届いたタスク（receiver_id == 自分）
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    /// 届いたタスクのリアルタイム購読（解除用）
    private var receivedTasksListener: ListenerRegistration?
    /// 送ったタスクのリアルタイム購読（承認待ち一覧用）
    private var sentTasksListener: ListenerRegistration?
    
    /// 送ったタスク（Firestore）。承認待ち一覧に利用
    @Published var sentTasks: [FirestoreTaskDTO] = []
    
    // MARK: - 通知用（重複防止・初回スナップショット除外）
    private var isFirstReceivedTasksSnapshot = true
    private var isFirstSentTasksSnapshot = true
    private var lastReceivedFirestoreTaskIds = Set<String>()
    private var lastReceivedTaskTitles: [String: String] = [:]
    private var lastSentFirestoreTaskIds = Set<String>()
    private var lastSentTaskTitles: [String: String] = [:]
    /// 送信タスクの status 遷移検知（差し戻し後の再報告で再度通知するため）
    private var lastSentTaskStatusById: [String: String] = [:]
    
    /// 承認待ちのタスク（送信者用）
    var pendingApprovalTasks: [FirestoreTaskDTO] {
        sentTasks.filter { $0.status == "pending_approval" }
    }
    
    weak var giftViewModel: GiftViewModel?
    weak var activityViewModel: ActivityViewModel?
    
    // MARK: - Filter & Search
    @Published var selectedFilter: TaskFilter = .all
    @Published var searchText = ""
    @Published var selectedEpicId: String?
    @Published var selectedPriority: TaskPriority?
    
    // MARK: - Computed Properties
    var filteredTasks: [Task] {
        var result = tasks
        
        // フィルタリング
        switch selectedFilter {
        case .all:
            break
        case .pending:
            result = result.filter {
                $0.status != .completed && $0.status != .archived
            }
        case .completed:
            result = result.filter { $0.status == .completed }
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            result = result.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDate(dueDate, inSameDayAs: today)
            }
        case .overdue:
            let now = Date()
            result = result.filter { task in
                guard let dueDate = task.dueDate,
                      task.status != .completed,
                      task.status != .archived else {
                    return false
                }
                return dueDate < now
            }
        }
        
        // エピックフィルタ
        if let epicId = selectedEpicId {
            result = result.filter { $0.epicId == epicId }
        }
        
        // 優先度フィルタ
        if let priority = selectedPriority {
            result = result.filter { $0.priority == priority }
        }
        
        // 検索
        if !searchText.isEmpty {
            result = result.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // ソート: 優先度 > 期限日 > 作成日
        return result.sorted { task1, task2 in
            // 優先度順
            let priorityOrder: [TaskPriority] = [.urgent, .high, .medium, .low]
            if let priority1Index = priorityOrder.firstIndex(of: task1.priority),
               let priority2Index = priorityOrder.firstIndex(of: task2.priority),
               priority1Index != priority2Index {
                return priority1Index < priority2Index
            }
            
            // 期限日順
            if let dueDate1 = task1.dueDate, let dueDate2 = task2.dueDate {
                if dueDate1 != dueDate2 {
                    return dueDate1 < dueDate2
                }
            } else if task1.dueDate != nil {
                return true
            } else if task2.dueDate != nil {
                return false
            }
            
            // 作成日順
            return task1.createdAt > task2.createdAt
        }
    }
    
    /// 今日やるタスク（期限が今日のもの ＋ 毎日ルーチンは常に含める）
    var todayTasks: [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return tasks.filter { task in
            if task.isRoutine {
                return task.status != .archived
            }
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today)
        }
    }
    
    var pendingTasks: [Task] {
        tasks.filter { $0.status != .completed && $0.status != .archived }
    }
    
    var completedTasks: [Task] {
        tasks.filter { $0.status == .completed }
    }
    
    // MARK: - Task Filter Enum
    enum TaskFilter: String, CaseIterable {
        case all = "全て"
        case pending = "未完了"
        case completed = "完了"
        case today = "今日"
        case overdue = "期限切れ"
    }
    
    // MARK: - Initialization
    init(tasks: [Task] = []) {
        self.tasks = tasks
        loadData()
    }
    
    // MARK: - Persistence (UserDefaults)
    func saveData() {
        guard let data = UserDefaultsStorage.encode(tasks) else { return }
        UserDefaultsStorage.save(data, key: UserDefaultsStorage.Key.tasks)
    }
    
    func loadData() {
        guard let data = UserDefaultsStorage.load(key: UserDefaultsStorage.Key.tasks),
              let decoded = UserDefaultsStorage.decode([Task].self, from: data) else {
            return
        }
        tasks = applyRevivalToLocalTasks(decoded)
        saveData()
    }
    
    /// 復活ロジック: (1) 累計タスク 未達かつ最終完了が今日でない → active (2) 毎日タスク 昨日までに完了 → 今日また未完了に
    private func applyRevivalToLocalTasks(_ list: [Task]) -> [Task] {
        let calendar = Calendar.current
        return list.map { task in
            var t = task
            guard t.status == .completed else { return t }
            // 累計達成型: currentCount < targetDays かつ 最終完了が今日でない → 復活
            if t.currentCount < t.targetDays,
               let last = t.lastCompletedDate, !calendar.isDateInToday(last) {
                t.status = .inProgress
                return t
            }
            // 毎日ルーチン: 完了日が今日でない → 今日またやるので未完了に戻す
            if t.isRoutine {
                let completedDay = t.completedDate ?? t.lastCompletedDate
                if completedDay == nil || !calendar.isDateInToday(completedDay!) {
                    t.status = .inProgress
                }
            }
            return t
        }
    }
    
    /// 届いたタスクの最新状態をローカルタスク一覧に反映
    private func mergeReceivedTasksIntoLocal(_ received: [FirestoreTaskDTO]) {
        for i in tasks.indices where tasks[i].senderId != nil {
            guard let dto = received.first(where: { $0.id == tasks[i].id }) else { continue }
            tasks[i].currentCount = dto.currentCount
            tasks[i].lastCompletedDate = dto.lastCompletedDate
            tasks[i].completionImageURL = dto.completionImageURL
            let previousStatus = tasks[i].status
            switch dto.status {
            case "active", "doing": tasks[i].status = .inProgress
            case "pending_approval": tasks[i].status = .pendingApproval
            case "completed":
                tasks[i].status = .completed
                if previousStatus != .completed {
                    let giftName = dto.giftName ?? "ギフト"
                    NotificationService.notifyTaskApprovedGiftUnlocked(taskTitle: dto.title, giftName: giftName)
                    if let gv = giftViewModel, let av = activityViewModel {
                        var t = tasks[i]
                        t.completedDate = Date()
                        gv.checkAndUnlockGifts(completedTask: t, taskViewModel: self, activityViewModel: av)
                    }
                }
            default: break
            }
        }
        saveData()
    }
    
    /// タスクを削除（ローカルから削除。Firestore タスクの場合は Firestore からも削除）
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveData()
        if task.rewardId != nil {
            _Concurrency.Task {
                try? await TaskRepository.shared.deleteTask(taskId: task.id)
            }
        }
    }
    
    /// ローカルデータを初期状態にリセット
    func resetData() {
        tasks = []
        saveData()
    }
    // MARK: - Task CRUD Operations
    
    /// タスクを作成
    func createTask(
        title: String,
        description: String? = nil,
        epicId: String? = nil,
        verificationMode: VerificationMode = .selfDeclaration,
        priority: TaskPriority = .medium,
        dueDate: Date? = nil,
        xpReward: Int = 10,
        rewardDisplayName: String? = nil,
        isRoutine: Bool = false
    ) -> Task {
        let currentUserId = Auth.auth().currentUser?.uid
        let creatorName = AuthManager.shared.userProfile?.displayName
        let newTask = Task(
            title: title,
            description: description,
            epicId: epicId,
            status: .pending,
            verificationMode: verificationMode,
            priority: priority,
            dueDate: dueDate,
            xpReward: xpReward,
            rewardDisplayName: rewardDisplayName,
            isRoutine: isRoutine,
            createdByUserId: currentUserId,
            createdByUserName: creatorName
        )
            tasks.append(newTask)
            saveData()
            return newTask
        }
    
    /// タスクを更新
    func updateTask(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }
        
        var updatedTask = task
        updatedTask.updatedAt = Date()
        tasks[index] = updatedTask
        saveData()
    }
    
    /// タスクをアーカイブ
    func archiveTask(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }
        
        var updatedTask = task
        updatedTask.status = .archived
        updatedTask.updatedAt = Date()
        tasks[index] = updatedTask
        saveData()
    }
    
    /// タスクのステータスを更新
    func updateTaskStatus(_ task: Task, status: TaskStatus) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            return
        }
        
        var updatedTask = task
        updatedTask.status = status
        updatedTask.updatedAt = Date()
        
        if status == .inProgress {
            updatedTask.updatedAt = Date()
        }
        
        tasks[index] = updatedTask
        saveData()
    }
    
    // MARK: - Task Completion

    /// タスクを完了する
    /// - Parameters:
    ///   - task: 完了するタスク
    ///   - photoURL: 写真証拠のURL（オプション）。届いたタスクで画像付きの場合は先に Storage にアップロードしたURLを渡す
    ///   - completionImageURL: 届いたタスクの完了報告画像URL（Storage アップロード済み）。photoURL の代わりにこちらを使う
    /// - Returns: 更新されたタスクと獲得したXP（届いたタスクで報告のみの場合は承認待ちとなりギフトはまだアンロックされない）
    func completeTask(_ task: Task, photoURL: String? = nil, completionImageURL: String? = nil) async throws -> (completedTask: Task, xpGained: Int) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            throw TaskError.taskNotFound
        }
        
        guard task.status != .completed else {
            throw TaskError.taskAlreadyCompleted
        }
        
        if task.status == .pendingApproval {
            throw TaskError.alreadyReported
        }
        
        // 検証モードチェック
        let evidenceURL = completionImageURL ?? photoURL
        if task.verificationMode == .photoEvidence && evidenceURL == nil {
            throw TaskError.photoEvidenceRequired
        }
        
        isLoading = true
        errorMessage = nil
        
        var updatedTask = task
        let isReceivedTask = task.senderId != nil
        
        if isReceivedTask, let rewardId = task.rewardId {
            // 届いたタスク: 完了報告（承認待ち）。Firestore は pending_approval、ギフトはアンロックしない
            try await TaskRepository.shared.reportTaskCompletion(
                taskId: task.id,
                rewardId: rewardId,
                completionImageURL: evidenceURL
            )
            updatedTask.currentCount = task.currentCount + 1
            updatedTask.lastCompletedDate = Date()
            updatedTask.completionImageURL = evidenceURL
            updatedTask.status = .pendingApproval
            updatedTask.updatedAt = Date()
            if updatedTask.currentCount >= updatedTask.targetDays {
                updatedTask.completedDate = Date()
            }
            // 受信者の端末: 報告送信の確認（送信者への通知は sentTasks リスナーで検知）
            NotificationService.notifyCompletionReportSubmitted()
        } else {
            // 自分で作ったタスク: 即時完了
            updatedTask.complete(with: evidenceURL)
            updatedTask.updatedAt = Date()
        }
        
        tasks[index] = updatedTask
        saveData()
        
        let xpGained = updatedTask.xpReward
        HapticManager.shared.taskCompleted()
        
        isLoading = false
        return (updatedTask, xpGained)
    }
    
    /// タスクを完了する（同期版、簡易使用用）
    func completeTaskSync(_ task: Task, photoURL: String? = nil, completion: @escaping (Task, Int) -> Void) {
        _Concurrency.Task { @MainActor [weak self] in            guard let self = self else { return }
            do {
                let result = try await self.completeTask(task, photoURL: photoURL)
                completion(result.completedTask, result.xpGained)
            } catch {
                // エラー処理
                print("Error completing task: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// IDでタスクを取得
    func getTask(by id: String) -> Task? {
        tasks.first { $0.id == id }
    }
    
    /// エピックIDでタスクを取得
    func getTasks(for epicId: String) -> [Task] {
        tasks.filter { $0.epicId == epicId }
    }
    
    /// エピックの進捗を計算
    func calculateEpicProgress(epicId: String) -> Double {
        let epicTasks = getTasks(for: epicId)
        guard !epicTasks.isEmpty else { return 0.0 }
        
        let completedCount = epicTasks.filter { $0.status == .completed }.count
        return Double(completedCount) / Double(epicTasks.count)
    }
    
    /// 複数エピックの平均進捗率（アクティビティリング用）
    func averageEpicProgress(epicIds: [String]) -> Double {
        guard !epicIds.isEmpty else { return 0.0 }
        let progressSum = epicIds.reduce(0.0) { $0 + calculateEpicProgress(epicId: $1) }
        return progressSum / Double(epicIds.count)
    }
    
    /// フィルタをリセット
    func resetFilters() {
        selectedFilter = .all
        searchText = ""
        selectedEpicId = nil
        selectedPriority = nil
    }
    
    // MARK: - Data Loading
    
    /// タスクを読み込む（UserDefaults 優先、無ければ空）。ログイン中なら届いた・送ったタスクのリスナーを開始する。
    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        loadData()
        startListeningReceivedTasks()
        startListeningSentTasks()
        isLoading = false
    }
    
    /// receiver_id が自分のUIDのタスクをリアルタイム購読開始
    func startListeningReceivedTasks() {
        stopListeningReceivedTasks()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        receivedTasksListener = TaskRepository.shared.addReceivedTasksListener(receiverId: uid) { [weak self] tasks in
            _Concurrency.Task { @MainActor in
                guard let self else { return }
                self.handleReceivedTasksSnapshot(tasks)
                self.receivedTasks = tasks
                self.mergeReceivedTasksIntoLocal(tasks)
                for dto in tasks where dto.needsRevival() {
                    try? await TaskRepository.shared.reviveTask(taskId: dto.id)
                }
            }
        }
    }
    
    /// sender_id が自分のUIDのタスクをリアルタイム購読開始（承認待ち一覧用）
    func startListeningSentTasks() {
        sentTasksListener?.remove()
        sentTasksListener = nil
        isFirstSentTasksSnapshot = true
        lastSentFirestoreTaskIds.removeAll()
        lastSentTaskTitles.removeAll()
        lastSentTaskStatusById.removeAll()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        sentTasksListener = TaskRepository.shared.addSentTasksListener(senderId: uid) { [weak self] tasks in
            _Concurrency.Task { @MainActor in
                guard let self else { return }
                await self.handleSentTasksSnapshot(tasks)
                self.sentTasks = tasks
            }
        }
    }
    
    /// 届いたタスクのリスナーを解除
    func stopListeningReceivedTasks() {
        receivedTasksListener?.remove()
        receivedTasksListener = nil
        receivedTasks = []
        isFirstReceivedTasksSnapshot = true
        lastReceivedFirestoreTaskIds.removeAll()
        lastReceivedTaskTitles.removeAll()
    }
    
    /// 送ったタスクのリスナーを解除
    func stopListeningSentTasks() {
        sentTasksListener?.remove()
        sentTasksListener = nil
        sentTasks = []
        isFirstSentTasksSnapshot = true
        lastSentFirestoreTaskIds.removeAll()
        lastSentTaskTitles.removeAll()
        lastSentTaskStatusById.removeAll()
    }
    
    /// 届いたタスクのうち status が "pending" のもの（受信BOX用）
    var pendingReceivedTasks: [FirestoreTaskDTO] {
        receivedTasks.filter { $0.status == "pending" }
    }
    
    /// 届いたタスクを「受け入れる」。Firestore を "active" にし、ローカルのタスク一覧・ギフトBOXに追加する。
    func acceptReceivedTask(_ dto: FirestoreTaskDTO, giftViewModel: GiftViewModel) async throws {
        if dto.status != "pending" { return }
        try await TaskRepository.shared.acceptReceivedTask(taskId: dto.id, rewardId: dto.rewardId)
        let giftName = dto.giftName ?? "ギフト"
        // タスク一覧に追加（実行中として表示）
        let newTask = Task(
            id: dto.id,
            title: dto.title,
            status: .inProgress,
            dueDate: dto.dueDate,
            rewardDisplayName: giftName,
            senderId: dto.senderId,
            rewardId: dto.rewardId,
            targetDays: dto.targetDays,
            currentCount: dto.currentCount,
            lastCompletedDate: dto.lastCompletedDate,
            senderName: dto.senderName,
            senderEmoji: dto.senderEmoji,
            senderTotalCompletedCount: dto.senderTotalCompletedCount,
            createdByUserId: dto.createdByUserId ?? dto.senderId,
            createdByUserName: dto.createdByUserName ?? dto.senderName
        )
        if !tasks.contains(where: { $0.id == newTask.id }) {
            tasks.append(newTask)
            saveData()
        }
        // ギフトBOXに追加（ロック状態、タスク完了で解禁）
        let condition = UnlockCondition(conditionType: .singleTask, targetIds: [dto.id])
        let newGift = Gift(
            id: dto.rewardId,
            title: giftName,
            description: dto.giftDescription,
            status: .locked,
            type: .friendAssigned,
            unlockCondition: condition,
            taskId: dto.id,
            assignedFromUserId: dto.senderId,
            assignedFromUserName: dto.senderName,
            assignedFromUserEmoji: dto.senderEmoji,
            createdByUserId: dto.createdByUserId ?? dto.senderId,
            createdByUserName: dto.createdByUserName ?? dto.senderName,
            linkedTaskTitle: dto.title,
            linkedTaskDueDate: dto.dueDate,
            price: 0,
            currency: "JPY"
        )
        if !giftViewModel.gifts.contains(where: { $0.id == newGift.id }) {
            giftViewModel.addGift(newGift)
        }
        if let senderProfile = await AuthManager.shared.fetchOtherUserProfile(uid: dto.senderId) {
            NotificationService.notifyTaskAccepted(
                senderFCMToken: senderProfile.fcmToken,
                receiverDisplayName: AuthManager.shared.userProfile?.displayName ?? "受信者",
                accepted: true
            )
        }
    }
    
    /// 届いたタスクを完了報告する（画像なし・承認待ちにする）
    func completeReceivedTask(_ dto: FirestoreTaskDTO) async throws {
        if dto.status == "completed" { return }
        try await TaskRepository.shared.completeReceivedTask(taskId: dto.id, rewardId: dto.rewardId)
    }
    
    /// 送信者が完了報告を承認。ギフトをアンロックし、タスクを完了にする。
    func approveTaskCompletion(_ dto: FirestoreTaskDTO) async throws {
        guard dto.status == "pending_approval" else { return }
        try await TaskRepository.shared.approveTaskCompletion(taskId: dto.id, rewardId: dto.rewardId)
    }
    
    /// 送信者が完了報告を差し戻し。タスクを active に戻す。
    func rejectTaskCompletion(_ dto: FirestoreTaskDTO) async throws {
        guard dto.status == "pending_approval" else { return }
        try await TaskRepository.shared.rejectTaskCompletion(taskId: dto.id)
    }
    
    /// タスクをリロード
    func refreshTasks() async {
        await loadTasks()
    }
    
    // MARK: - 通知（Firestore スナップショット）
    
    /// 受信タスク一覧の変化: 新着 pending / 削除を検知してローカル通知
    private func handleReceivedTasksSnapshot(_ tasks: [FirestoreTaskDTO]) {
        let currentIds = Set(tasks.map(\.id))
        let titles = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0.title) })
        
        if isFirstReceivedTasksSnapshot {
            isFirstReceivedTasksSnapshot = false
            lastReceivedFirestoreTaskIds = currentIds
            lastReceivedTaskTitles = titles
            return
        }
        
        let removedIds = lastReceivedFirestoreTaskIds.subtracting(currentIds)
        for id in removedIds {
            let title = lastReceivedTaskTitles[id] ?? "タスク"
            NotificationService.notifyReceivedTaskRemoved(taskTitle: title)
        }
        
        for dto in tasks where dto.status == "pending" {
            if !lastReceivedFirestoreTaskIds.contains(dto.id) {
                NotificationService.notifyIncomingTask(
                    senderName: dto.senderName ?? "ユーザー",
                    taskTitle: dto.title
                )
            }
        }
        
        lastReceivedFirestoreTaskIds = currentIds
        lastReceivedTaskTitles = titles
    }
    
    /// 送信タスク一覧の変化: 承認申請（pending_approval へ遷移）/ 削除を検知
    private func handleSentTasksSnapshot(_ tasks: [FirestoreTaskDTO]) async {
        let currentIds = Set(tasks.map(\.id))
        let titles = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0.title) })
        
        if isFirstSentTasksSnapshot {
            isFirstSentTasksSnapshot = false
            lastSentTaskStatusById = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0.status) })
            lastSentFirestoreTaskIds = currentIds
            lastSentTaskTitles = titles
            return
        }
        
        let removedIds = lastSentFirestoreTaskIds.subtracting(currentIds)
        for id in removedIds {
            let title = lastSentTaskTitles[id] ?? "タスク"
            NotificationService.notifySentTaskRemovedAsCreator(taskTitle: title)
        }
        
        for dto in tasks {
            let prev = lastSentTaskStatusById[dto.id]
            if dto.status == "pending_approval", prev != "pending_approval" {
                let name = await AuthManager.shared.fetchOtherUserProfile(uid: dto.receiverId)?.displayName ?? "相手"
                NotificationService.notifyCompletionReportReceived(receiverName: name, taskTitle: dto.title)
            }
        }
        
        lastSentTaskStatusById = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0.status) })
        lastSentFirestoreTaskIds = currentIds
        lastSentTaskTitles = titles
    }
}

// MARK: - Task Error
enum TaskError: LocalizedError {
    case taskNotFound
    case taskAlreadyCompleted
    case alreadyReported
    case photoEvidenceRequired
    case invalidTaskData
    
    var errorDescription: String? {
        switch self {
        case .taskNotFound:
            return "タスクが見つかりません"
        case .taskAlreadyCompleted:
            return "このタスクは既に完了しています"
        case .alreadyReported:
            return "このタスクは既に完了報告済みです。送信者の承認をお待ちください。"
        case .photoEvidenceRequired:
            return "このタスクには写真証拠が必要です"
        case .invalidTaskData:
            return "タスクデータが無効です"
        }
    }
}
