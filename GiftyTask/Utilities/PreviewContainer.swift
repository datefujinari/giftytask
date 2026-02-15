import Foundation

// MARK: - Preview Container (モックデータ)
struct PreviewContainer {
    
    /// LINEギフト公式トップURL（「利用する」押下でSafari/ブラウザから開く）
    /// 本番ではアンロック時に発行された個別ギフトURLを設定可能
    static let lineGiftOfficialURL = "https://linegift.line.me/"
    
    // MARK: - Mock User
    static let mockUser = User(
        id: "user-001",
        displayName: "プレビューユーザー",
        email: "preview@example.com",
        level: 5,
        xp: 250,
        totalXP: 450,
        currentTheme: "default",
        unlockedThemes: ["default", "dark", "blue"],
        unlockedBadges: ["first_task", "streak_7", "epic_completed"]
    )
    
    // MARK: - Mock Epics
    static let mockEpics: [Epic] = [
        Epic(
            id: "epic-001",
            title: "健康習慣の確立",
            description: "毎日の運動と食事管理で健康的な生活を目指す",
            status: .active,
            giftId: "gift-001",
            taskIds: ["task-001", "task-002", "task-003"],
            startDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            targetDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
        ),
        Epic(
            id: "epic-002",
            title: "プログラミングスキル向上",
            description: "SwiftUIとiOS開発のスキルを向上させる",
            status: .active,
            giftId: "gift-002",
            taskIds: ["task-004", "task-005"],
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            targetDate: Calendar.current.date(byAdding: .day, value: 60, to: Date())
        )
    ]
    
    // MARK: - Mock Tasks
    static let mockTasks: [Task] = [
        // 健康習慣の確立 - Epic関連タスク
        Task(
            id: "task-001",
            title: "朝のジョギング30分",
            description: "健康維持のためのルーティン",
            epicId: "epic-001",
            status: .pending,
            verificationMode: .photoEvidence,
            priority: .high,
            dueDate: Calendar.current.startOfDay(for: Date()),
            xpReward: 20
        ),
        Task(
            id: "task-002",
            title: "野菜を200g食べる",
            description: "バランスの取れた食事を心がける",
            epicId: "epic-001",
            status: .pending,
            verificationMode: .selfDeclaration,
            priority: .medium,
            dueDate: Calendar.current.startOfDay(for: Date()),
            xpReward: 15
        ),
        Task(
            id: "task-003",
            title: "水分補給2リットル",
            description: "1日の目標水分量を摂取",
            epicId: "epic-001",
            status: .completed,
            verificationMode: .selfDeclaration,
            priority: .low,
            completedDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
            xpReward: 10
        ),
        
        // プログラミングスキル向上 - Epic関連タスク
        Task(
            id: "task-004",
            title: "SwiftUIチュートリアル完了",
            description: "Apple公式ドキュメントを読む",
            epicId: "epic-002",
            status: .inProgress,
            verificationMode: .selfDeclaration,
            priority: .high,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
            xpReward: 30
        ),
        Task(
            id: "task-005",
            title: "GitHubにコードをコミット",
            description: "今日の学習内容をプッシュ",
            epicId: "epic-002",
            status: .pending,
            verificationMode: .photoEvidence,
            priority: .medium,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            xpReward: 25
        ),
        
        // 独立タスク
        Task(
            id: "task-006",
            title: "読書30分",
            description: "技術書「iOS開発の教科書」を読む",
            status: .pending,
            verificationMode: .selfDeclaration,
            priority: .medium,
            dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
            xpReward: 15
        ),
        Task(
            id: "task-007",
            title: "プレゼン資料作成",
            description: "来週のミーティング用資料",
            status: .pending,
            verificationMode: .selfDeclaration,
            priority: .urgent,
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            xpReward: 40
        ),
        Task(
            id: "task-008",
            title: "散歩20分",
            description: "リフレッシュのために外を歩く",
            status: .completed,
            verificationMode: .photoEvidence,
            priority: .low,
            completedDate: Calendar.current.date(byAdding: .hour, value: -5, to: Date()),
            photoEvidenceURL: "https://example.com/photo.jpg",
            xpReward: 10
        )
    ]
    
    // MARK: - Mock Gifts
    static let mockGifts: [Gift] = [
        // ロック済みギフト
        Gift(
            id: "gift-001",
            title: "スターバックスギフトカード 1,000円",
            description: "健康習慣の確立エピック完了報酬",
            status: .locked,
            type: .selfReward,
            unlockCondition: UnlockCondition(
                conditionType: .epicCompletion,
                epicId: "epic-001"
            ),
            epicId: "epic-001",
            price: 1000,
            currency: "JPY"
        ),
        Gift(
            id: "gift-002",
            title: "Amazonギフト券 3,000円",
            description: "プログラミングスキル向上エピック完了報酬",
            status: .locked,
            type: .selfReward,
            unlockCondition: UnlockCondition(
                conditionType: .epicCompletion,
                epicId: "epic-002"
            ),
            epicId: "epic-002",
            price: 3000,
            currency: "JPY"
        ),
        Gift(
            id: "gift-003",
            title: "iTunesギフトカード 500円",
            description: "レベル5到達報酬",
            status: .locked,
            type: .selfReward,
            unlockCondition: UnlockCondition(
                conditionType: .xpThreshold,
                xpThreshold: 500
            ),
            price: 500,
            currency: "JPY"
        ),
        
        // アンロック済みギフト（LINEギフト公式へ誘導）
        Gift(
            id: "gift-004",
            title: "セブン-イレブンギフト券 500円",
            description: "初回タスク完了報酬",
            giftURL: PreviewContainer.lineGiftOfficialURL,
            status: .unlocked,
            type: .selfReward,
            unlockCondition: UnlockCondition(
                conditionType: .taskCompletion,
                taskId: "task-008"
            ),
            taskId: "task-008",
            price: 500,
            currency: "JPY",
            gifteeGiftId: "giftee-001",
            unlockedAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date())
        )
    ]
    
    // MARK: - Mock Activity Data
    static let mockActivityRingData = ActivityRingData(
        move: 0.75,      // 完了タスク 3/4
        exercise: 0.6,   // エピック進捗 60%
        stand: 0.85      // アクティブ日 17/20
    )
    
    static let mockActivityData = ActivityData(
        userId: "user-001",
        date: Date(),
        completedTasksCount: 3,
        totalTasksCount: 8,
        xpGained: 50,
        completionRate: 0.375
    )
    
    static let mockStreakData = StreakData(
        currentStreak: 5,
        longestStreak: 10,
        lastActivityDate: Date()
    )
    
    // MARK: - Helper Methods
    
    /// エピックIDでタスクをフィルタ
    static func tasks(for epicId: String) -> [Task] {
        mockTasks.filter { $0.epicId == epicId }
    }
    
    /// 今日のタスクを取得
    static func todayTasks() -> [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        return mockTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: today)
        }
    }
    
    /// 未完了タスクを取得
    static func pendingTasks() -> [Task] {
        mockTasks.filter { $0.status != .completed && $0.status != .archived }
    }
    
    /// 完了済みタスクを取得
    static func completedTasks() -> [Task] {
        mockTasks.filter { $0.status == .completed }
    }
}

