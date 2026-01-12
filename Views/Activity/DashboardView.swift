import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @State private var user: User = PreviewContainer.mockUser
    @State private var todayTasks: [Task] = PreviewContainer.todayTasks()
    @State private var ringData: ActivityRingData = PreviewContainer.mockActivityRingData
    @State private var streakData: StreakData = PreviewContainer.mockStreakData
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ユーザー情報カード
                    UserInfoCard(user: user)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // アクティビティリング
                    ActivityRingCardView(
                        ringData: ringData,
                        completedTasks: todayTasks.filter { $0.status == .completed }.count,
                        goalTasks: 5,
                        epicProgress: 0.6,
                        activeDays: 17,
                        totalDays: 20
                    )
                    .padding(.horizontal)
                    
                    // ストリーク情報
                    StreakCardView(streakData: streakData)
                        .padding(.horizontal)
                    
                    // 今日のタスク
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("今日のタスク")
                                .font(.system(size: 22, weight: .bold))
                            
                            Spacer()
                            
                            Text("\(todayTasks.filter { $0.status == .completed }.count)/\(todayTasks.count)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if todayTasks.isEmpty {
                            EmptyStateView(
                                icon: "checkmark.circle.fill",
                                title: "今日のタスクはありません",
                                message: "新しいタスクを作成しましょう"
                            )
                            .frame(height: 200)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(todayTasks.prefix(5)) { task in
                                        TaskCardView(
                                            task: task,
                                            onComplete: { completedTask, photo in
                                                if let index = todayTasks.firstIndex(where: { $0.id == completedTask.id }) {
                                                    todayTasks[index] = completedTask
                                                }
                                                HapticManager.shared.taskCompleted()
                                                
                                                // リングデータを更新
                                                updateRingData()
                                            }
                                        )
                                        .frame(width: 320)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                    
                    // エピック進捗
                    VStack(alignment: .leading, spacing: 16) {
                        Text("進行中のエピック")
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal)
                        
                        ForEach(PreviewContainer.mockEpics.prefix(2)) { epic in
                            EpicProgressCard(epic: epic)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .padding(.bottom)
            }
            .navigationTitle("ダッシュボード")
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
    
    private func updateRingData() {
        let completedCount = todayTasks.filter { $0.status == .completed }.count
        let goalCount = 5
        ringData.move = min(Double(completedCount) / Double(goalCount), 1.0)
    }
}

// MARK: - User Info Card
struct UserInfoCard: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(user.displayName)
                        .font(.system(size: 24, weight: .bold))
                    
                    HStack(spacing: 16) {
                        Label {
                            Text("Lv.\(user.level)")
                                .font(.system(size: 16, weight: .semibold))
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                        
                        Label {
                            Text("\(user.totalXP) XP")
                                .font(.system(size: 16, weight: .semibold))
                        } icon: {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // レベルプログレス
                VStack(alignment: .trailing, spacing: 8) {
                    Text("次のレベルまで")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("\(user.xpToNextLevel) XP")
                        .font(.system(size: 18, weight: .bold))
                    
                    ProgressView(value: Double(user.totalXP % 100), total: 100)
                        .frame(width: 100)
                        .tint(.blue)
                }
            }
        }
        .padding(20)
        .glassmorphism(cornerRadius: 20)
    }
}

// MARK: - Streak Card View
struct StreakCardView: View {
    let streakData: StreakData
    
    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("連続日数")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("\(streakData.currentStreak)日")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            Divider()
                .frame(height: 50)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("最長記録")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("\(streakData.longestStreak)日")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.purple)
            }
            
            Spacer()
            
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange.opacity(0.5))
        }
        .padding(20)
        .glassmorphism(cornerRadius: 20)
    }
}

// MARK: - Epic Progress Card
struct EpicProgressCard: View {
    let epic: Epic
    @State private var tasks: [Task] = []
    
    var progress: Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completedCount = tasks.filter { $0.status == .completed }.count
        return Double(completedCount) / Double(tasks.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(epic.title)
                    .font(.system(size: 18, weight: .bold))
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            
            if let description = epic.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            ProgressView(value: progress)
                .tint(.blue)
            
            HStack {
                Text("\(tasks.filter { $0.status == .completed }.count)/\(tasks.count) タスク完了")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let targetDate = epic.targetDate {
                    Text("期限: \(targetDate, style: .date)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .glassmorphism(cornerRadius: 20)
        .onAppear {
            tasks = PreviewContainer.tasks(for: epic.id)
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
}

