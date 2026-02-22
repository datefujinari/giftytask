import Foundation
import Combine

// MARK: - Task ViewModel
@MainActor
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var tasks: [Task] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
    
    var todayTasks: [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: today)
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
        tasks = decoded
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
            isRoutine: isRoutine
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
    
    /// タスクを削除
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveData()
        // await firebaseService.deleteTask(task.id)
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
    ///   - photoURL: 写真証拠のURL（オプション）
    /// - Returns: 完了したタスクと獲得したXP
    func completeTask(_ task: Task, photoURL: String? = nil) async throws -> (completedTask: Task, xpGained: Int) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else {
            throw TaskError.taskNotFound
        }
        
        guard task.status != .completed else {
            throw TaskError.taskAlreadyCompleted
        }
        
        // 検証モードチェック
        if task.verificationMode == .photoEvidence && photoURL == nil {
            throw TaskError.photoEvidenceRequired
        }
        
        isLoading = true
        errorMessage = nil
        
        var completedTask = task
        completedTask.complete(with: photoURL)
        completedTask.updatedAt = Date()
        
        tasks[index] = completedTask
        saveData()
        
        let xpGained = completedTask.xpReward
        
        // ハプティックフィードバック
        HapticManager.shared.taskCompleted()
        
        // TODO: FirebaseServiceに保存
        // await firebaseService.updateTask(completedTask)
        
        // TODO: エピック進捗の更新を通知
        // NotificationCenter.default.post(
        //     name: .taskCompleted,
        //     object: nil,
        //     userInfo: ["task": completedTask, "epicId": completedTask.epicId as Any]
        // )
        
        isLoading = false
        return (completedTask, xpGained)
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
    
    /// タスクを読み込む（UserDefaults 優先、無ければ空）
    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        loadData()
        isLoading = false
    }
    
    /// タスクをリロード
    func refreshTasks() async {
        await loadTasks()
    }
}

// MARK: - Task Error
enum TaskError: LocalizedError {
    case taskNotFound
    case taskAlreadyCompleted
    case photoEvidenceRequired
    case invalidTaskData
    
    var errorDescription: String? {
        switch self {
        case .taskNotFound:
            return "タスクが見つかりません"
        case .taskAlreadyCompleted:
            return "このタスクは既に完了しています"
        case .photoEvidenceRequired:
            return "このタスクには写真証拠が必要です"
        case .invalidTaskData:
            return "タスクデータが無効です"
        }
    }
}
