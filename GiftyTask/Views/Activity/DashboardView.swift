import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    @EnvironmentObject var epicViewModel: EpicViewModel
    @State private var showAddTask = false
    @State private var heatmapTheme = HeatmapTheme()
    @State private var showResetConfirm = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 24) {
                    // ユーザー情報カード（XP・レベルは ActivityViewModel.currentUser でリアルタイム更新）
                    UserInfoCard(user: activityViewModel.currentUser)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // アクティビティヒートマップ（GitHub風）
                    GiftyHeatmapView(
                        heatmapData: activityViewModel.heatmapData,
                        theme: Binding(
                            get: { activityViewModel.heatmapTheme },
                            set: { activityViewModel.heatmapTheme = $0; activityViewModel.saveData() }
                        )
                    )
                    .padding(.horizontal)
                    
                    // ストリーク情報
                    StreakCardView(streakData: activityViewModel.streakData)
                        .padding(.horizontal)
                    
                    // 今日のタスク
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("今日のタスク")
                                .font(.system(size: 22, weight: .bold))
                            
                            Spacer()
                            
                            Text("\(taskViewModel.todayTasks.filter { $0.status == .completed }.count)/\(taskViewModel.todayTasks.count)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        if taskViewModel.todayTasks.isEmpty {
                            EmptyStateView(
                                icon: "checkmark.circle.fill",
                                title: "今日のタスクはありません",
                                message: "新しいタスクを作成しましょう"
                            )
                            .frame(height: 200)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(taskViewModel.todayTasks.prefix(5).indices, id: \.self) { index in
                                        TaskCardView(
                                            task: Binding(
                                                get: { taskViewModel.todayTasks[index] },
                                                set: { taskViewModel.updateTask($0) }
                                            ),
                                            onComplete: { completedTask, photo in
                                                // タスク完了: ViewModel完了 → XP加算・レベルアップ → リング更新 → ハプティック
                                                _Concurrency.Task { @MainActor in
                                                    do {
                                                        let photoURL = photo != nil ? "photo_\(completedTask.id)" : nil
                                                        let result = try await taskViewModel.completeTask(completedTask, photoURL: photoURL)
                                                        
                                                        // アクティビティ記録（完了数・XP・ストリーク）
                                                        activityViewModel.recordTaskCompletion(
                                                            xpGained: result.xpGained,
                                                            totalTasksCount: taskViewModel.todayTasks.count
                                                        )
                                                        
                                                        // XP加算し、レベルアップしたら専用ハプティック
                                                        let leveledUp = activityViewModel.addXPToUser(result.xpGained)
                                                        if leveledUp {
                                                            HapticManager.shared.levelUp()
                                                        }
                                                        
                                                        // アクティビティリングをリアルタイム更新
                                                        activityViewModel.generateHeatmapData()
                                                        
                                                        giftViewModel.checkAndUnlockGifts(
                                                            completedTask: result.completedTask,
                                                            taskViewModel: taskViewModel,
                                                            activityViewModel: activityViewModel
                                                        )
                                                    } catch {
                                                        print("❌ エラー: \(error.localizedDescription)")
                                                    }
                                                }
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
                        
                        ForEach(epicViewModel.epics.prefix(2)) { epic in
                            EpicProgressCard(epic: epic)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    
                    // リセットボタン
                    Button {
                        showResetConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("データをリセット")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
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
                
                AddTaskFAB {
                    HapticManager.shared.mediumImpact()
                    showAddTask = true
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView(isPresented: $showAddTask)
                    .environmentObject(taskViewModel)
                    .environmentObject(activityViewModel)
            }
            .sheet(item: Binding(
                get: { giftViewModel.lastUnlockedGift },
                set: { giftViewModel.lastUnlockedGift = $0 }
            )) { gift in
                CelebrationModal(message: "おめでとう🎉", subtitle: gift.title)
            }
            .alert("データをリセット", isPresented: $showResetConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("リセット", role: .destructive) {
                    performReset()
                }
            } message: {
                Text("タスク、ギフト、エピック、継続日数などすべてのローカルデータが削除され、初期状態に戻ります。この操作は取り消せません。")
            }
        }
        .task {
            await taskViewModel.loadTasks()
            await activityViewModel.loadActivityData()
        }
    }
    
    /// ローカルデータを初期状態にリセット
    private func performReset() {
        taskViewModel.resetData()
        giftViewModel.resetData()
        activityViewModel.resetData()
        epicViewModel.resetData()
    }
    
    /// エピックの平均進捗率を計算
    private func calculateEpicProgress() -> Double {
        let epics = epicViewModel.epics.prefix(2)
        guard !epics.isEmpty else { return 0.0 }
        
        var totalProgress = 0.0
        for epic in epics {
            let tasks = taskViewModel.getTasks(for: epic.id)
            guard !tasks.isEmpty else { continue }
            let completedCount = tasks.filter { $0.status == .completed }.count
            totalProgress += Double(completedCount) / Double(tasks.count)
        }
        
        return totalProgress / Double(epics.count)
    }
    
}


// MARK: - Heatmap Card View（レガシー）
struct HeatmapCardView: View {
    let heatmapData: [HeatmapData]
    
    // 過去12週間（84日）のデータを表示
    var displayData: [HeatmapData] {
        Array(heatmapData.suffix(84))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("アクティビティヒートマップ")
                .font(.system(size: 22, weight: .bold))
            
            // ヒートマップグリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(displayData, id: \.date) { data in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: data.colorHex))
                        .frame(width: 12, height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                        )
                }
            }
            
            // 凡例
            HStack {
                Text("少ない")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { intensity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: intensityToColor(intensity)))
                            .frame(width: 10, height: 10)
                    }
                }
                
                Text("多い")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .glassmorphism(cornerRadius: 20)
    }
    
    private func intensityToColor(_ intensity: Int) -> String {
        switch intensity {
        case 0: return "#EBEDF0"
        case 1: return "#C6E48B"
        case 2: return "#7BC96F"
        case 3: return "#239A3B"
        case 4: return "#196127"
        default: return "#EBEDF0"
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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
                    
                    ProgressView(value: user.currentLevelProgressValue, total: user.currentLevelProgressTotal)
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
        .environmentObject(TaskViewModel())
        .environmentObject(ActivityViewModel())
        .environmentObject(GiftViewModel())
        .environmentObject(EpicViewModel())
}

