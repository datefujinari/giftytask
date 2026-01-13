import Foundation

// MARK: - Activity Data Model
struct ActivityData: Identifiable, Codable, Hashable {
    let id: String
    var userId: String
    var date: Date
    var completedTasksCount: Int
    var totalTasksCount: Int
    var xpGained: Int
    var completionRate: Double // 0.0 - 1.0
    
    // 計算プロパティ
    var dailyGoal: Int {
        // デフォルト目標（カスタマイズ可能）
        return 5
    }
    
    var goalAchieved: Bool {
        return completedTasksCount >= dailyGoal
    }
    
    // 初期化
    init(
        id: String = UUID().uuidString,
        userId: String,
        date: Date,
        completedTasksCount: Int = 0,
        totalTasksCount: Int = 0,
        xpGained: Int = 0,
        completionRate: Double = 0.0
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.completedTasksCount = completedTasksCount
        self.totalTasksCount = totalTasksCount
        self.xpGained = xpGained
        self.completionRate = completionRate
    }
    
    // 完了率を計算
    mutating func calculateCompletionRate() {
        if totalTasksCount > 0 {
            completionRate = Double(completedTasksCount) / Double(totalTasksCount)
        } else {
            completionRate = 0.0
        }
    }
}

// MARK: - Activity Ring Data
struct ActivityRingData: Codable, Hashable {
    var move: Double // 0.0 - 1.0 (完了タスク数/目標タスク数)
    var exercise: Double // 0.0 - 1.0 (エピック進捗)
    var stand: Double // 0.0 - 1.0 (アクティブ日数/総日数)
    
    init(move: Double = 0.0, exercise: Double = 0.0, stand: Double = 0.0) {
        self.move = min(max(move, 0.0), 1.0)
        self.exercise = min(max(exercise, 0.0), 1.0)
        self.stand = min(max(stand, 0.0), 1.0)
    }
    
    // すべてのリングが閉じているか
    var allClosed: Bool {
        return move >= 1.0 && exercise >= 1.0 && stand >= 1.0
    }
}

// MARK: - Heatmap Data
struct HeatmapData: Codable, Hashable {
    var date: Date
    var intensity: Int // 0-4 (活動強度: 0=なし, 1=低, 2=中, 3=高, 4=最高)
    
    init(date: Date, intensity: Int = 0) {
        self.date = date
        self.intensity = min(max(intensity, 0), 4)
    }
    
    // 色を決定（GitHubスタイル）
    var colorHex: String {
        switch intensity {
        case 0: return "#EBEDF0" // なし
        case 1: return "#C6E48B" // 低
        case 2: return "#7BC96F" // 中
        case 3: return "#239A3B" // 高
        case 4: return "#196127" // 最高
        default: return "#EBEDF0"
        }
    }
}

// MARK: - Streak Data
struct StreakData: Codable, Hashable {
    var currentStreak: Int // 現在の連続日数
    var longestStreak: Int // 最長連続日数
    var lastActivityDate: Date?
    
    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastActivityDate: Date? = nil
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
    }
    
    // ストリークを更新
    mutating func updateStreak(with date: Date) {
        guard let lastDate = lastActivityDate else {
            // 初回
            currentStreak = 1
            longestStreak = 1
            lastActivityDate = date
            return
        }
        
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: lastDate) {
            // 同じ日: ストリーク変更なし
            return
        } else if calendar.isDate(date, equalTo: lastDate, toGranularity: .day),
                  calendar.dateComponents([.day], from: lastDate, to: date).day == 1 {
            // 連続日
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
            lastActivityDate = date
        } else {
            // ストリークが途切れた
            currentStreak = 1
            lastActivityDate = date
        }
    }
}

