import Foundation
import Combine

// MARK: - Activity ViewModel
@MainActor
class ActivityViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var activityRingData: ActivityRingData = ActivityRingData()
    @Published var streakData: StreakData = StreakData()
    @Published var heatmapData: [HeatmapData] = []
    @Published var dailyActivityData: [ActivityData] = []
    @Published var currentUser: User // XP・レベル管理（タスク完了で更新、ダッシュボードと同期）
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Configuration
    var dailyGoal: Int = 5 // デフォルトの日次目標タスク数
    var activeDaysPeriod: Int = 20 // アクティブ日数の計算期間（日数）
    
    // MARK: - Initialization
    init(currentUser: User = PreviewContainer.mockUser) {
        self.currentUser = currentUser
        initializeMockData()
    }
    
    // MARK: - XP & Level
    
    /// タスク完了で獲得したXPをユーザーに加算し、レベルアップしたかどうかを返す
    /// - Parameter xp: 加算するXP
    /// - Returns: レベルアップした場合 true
    func addXPToUser(_ xp: Int) -> Bool {
        var user = currentUser
        let leveledUp = user.addXP(xp)
        currentUser = user
        return leveledUp
    }
    // MARK: - Activity Ring Calculation
    
    /// アクティビティリングデータを計算
    /// - Parameters:
    ///   - completedTasksCount: 今日完了したタスク数
    ///   - totalTasksCount: 今日の総タスク数
    ///   - epicProgress: エピックの平均進捗率
    func calculateActivityRing(
        completedTasksCount: Int,
        totalTasksCount: Int,
        epicProgress: Double
    ) {
        // Move Ring: 完了タスク数/目標タスク数
        let moveValue = min(Double(completedTasksCount) / Double(dailyGoal), 1.0)
        
        // Exercise Ring: エピック進捗率
        let exerciseValue = min(max(epicProgress, 0.0), 1.0)
        
        // Stand Ring: アクティブ日数/総日数
        let activeDays = calculateActiveDays()
        let standValue = min(Double(activeDays) / Double(activeDaysPeriod), 1.0)
        
        activityRingData = ActivityRingData(
            move: moveValue,
            exercise: exerciseValue,
            stand: standValue
        )
    }
    
    /// アクティブ日数を計算（過去N日間でタスクを完了した日数）
    func calculateActiveDays() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -activeDaysPeriod, to: today) ?? today
        
        // アクティビティデータからアクティブ日数を計算
        let activeDaysSet = Set(
            dailyActivityData
                .filter { activity in
                    let activityDate = calendar.startOfDay(for: activity.date)
                    return activityDate >= startDate &&
                           activityDate <= today &&
                           activity.completedTasksCount > 0
                }
                .map { calendar.startOfDay(for: $0.date) }
        )
        
        return activeDaysSet.count
    }
    
    // MARK: - Streak Management
    
    /// ストリークを更新（タスク完了時に呼び出す）
    func updateStreak() {
        let today = Date()
        streakData.updateStreak(with: today)
    }
    
    /// ストリークデータをリセット
    func resetStreak() {
        streakData = StreakData()
    }
    
    // MARK: - Daily Activity Management
    
    /// 今日のアクティビティデータを取得または作成
    func getTodayActivity() -> ActivityData {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let existing = dailyActivityData.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            return existing
        }
        
        // 新規作成
        let newActivity = ActivityData(
            userId: "current-user", // TODO: 実際のユーザーIDに置き換え
            date: today
        )
        dailyActivityData.append(newActivity)
        return newActivity
    }
    
    /// タスク完了時にアクティビティデータを更新
    /// - Parameters:
    ///   - xpGained: 獲得したXP
    ///   - taskCount: 今日の総タスク数
    func recordTaskCompletion(xpGained: Int, totalTasksCount: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 今日のアクティビティデータを取得または作成
        var todayActivity = getTodayActivity()
        
        // 完了タスク数を増やす
        todayActivity.completedTasksCount += 1
        todayActivity.totalTasksCount = totalTasksCount
        todayActivity.xpGained += xpGained
        todayActivity.calculateCompletionRate()
        
        // データを更新
        if let index = dailyActivityData.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            dailyActivityData[index] = todayActivity
        } else {
            dailyActivityData.append(todayActivity)
        }
        
        // ストリークを更新
        updateStreak()
        
        // TODO: FirebaseServiceに保存
        // await firebaseService.updateActivityData(todayActivity)
    }
    
    // MARK: - Heatmap Generation
    
    /// ヒートマップデータを生成（過去1年間）
    func generateHeatmapData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today) ?? today
        
        var heatmap: [HeatmapData] = []
        
        // 過去1年間の各日についてヒートマップデータを生成
        var currentDate = oneYearAgo
        while currentDate <= today {
            let activity = dailyActivityData.first { calendar.isDate($0.date, inSameDayAs: currentDate) }
            let intensity = calculateIntensity(for: activity)
            
            heatmap.append(HeatmapData(date: currentDate, intensity: intensity))
            
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        heatmapData = heatmap
    }
    
    /// アクティビティデータから強度を計算（0-4）
    private func calculateIntensity(for activity: ActivityData?) -> Int {
        guard let activity = activity else { return 0 }
        
        let completedCount = activity.completedTasksCount
        
        // 強度の計算ロジック
        if completedCount >= dailyGoal * 2 {
            return 4 // 最高
        } else if completedCount >= dailyGoal {
            return 3 // 高
        } else if completedCount >= dailyGoal / 2 {
            return 2 // 中
        } else if completedCount > 0 {
            return 1 // 低
        } else {
            return 0 // なし
        }
    }
    
    // MARK: - Data Loading

    /// アクティビティデータを読み込む
    func loadActivityData() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: FirebaseServiceから取得
        // do {
        //     dailyActivityData = try await firebaseService.fetchActivityData()
        //     streakData = try await firebaseService.fetchStreakData()
        // } catch {
        //     errorMessage = "アクティビティデータの読み込みに失敗しました: \(error.localizedDescription)"
        // }
        
        // 現時点ではモックデータを使用
        try? await _Concurrency.Task.sleep(nanoseconds: 200_000_000) // 0.2秒待機
        
        // モックデータの初期化（既にinitで呼ばれている場合はスキップ）
        if dailyActivityData.isEmpty {
            initializeMockData()
        }
        
        isLoading = false
    }
    /// モックデータの初期化
    private func initializeMockData() {
        // ストリークデータ
        streakData = PreviewContainer.mockStreakData
        
        // 過去数日分のアクティビティデータを生成
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let activity = ActivityData(
                    userId: "current-user",
                    date: date,
                    completedTasksCount: i < 3 ? 3 + i : 0,
                    totalTasksCount: 5,
                    xpGained: (3 + i) * 10,
                    completionRate: Double(3 + i) / 5.0
                )
                dailyActivityData.append(activity)
            }
        }
        
        // ヒートマップデータを生成
        generateHeatmapData()
    }
    
    /// アクティビティデータをリロード
    func refreshActivityData() async {
        await loadActivityData()
    }
    // MARK: - Helper Methods
    
    /// 指定日のアクティビティデータを取得
    func getActivityData(for date: Date) -> ActivityData? {
        let calendar = Calendar.current
        return dailyActivityData.first { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    /// 過去N日間の平均完了率を計算
    func calculateAverageCompletionRate(days: Int = 7) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
        
        let recentActivities = dailyActivityData.filter { activity in
            let activityDate = calendar.startOfDay(for: activity.date)
            return activityDate >= startDate && activityDate <= today
        }
        
        guard !recentActivities.isEmpty else { return 0.0 }
        
        let totalRate = recentActivities.reduce(0.0) { $0 + $1.completionRate }
        return totalRate / Double(recentActivities.count)
    }
    
    /// 目標達成日数を取得（過去N日間）
    func getGoalAchievedDays(days: Int = 7) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: today) ?? today
        
        return dailyActivityData.filter { activity in
            let activityDate = calendar.startOfDay(for: activity.date)
            return activityDate >= startDate &&
                   activityDate <= today &&
                   activity.goalAchieved
        }.count
    }
}
