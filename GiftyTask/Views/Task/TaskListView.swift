import SwiftUI

// MARK: - Task List View
struct TaskListView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    @EnvironmentObject var epicViewModel: EpicViewModel
    @State private var showAddTask = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                // 検索バー
                SearchBar(text: $taskViewModel.searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // フィルタ
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskViewModel.TaskFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: taskViewModel.selectedFilter == filter
                            ) {
                                taskViewModel.selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // ローディング表示
                if taskViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // タスク一覧
                else if taskViewModel.filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: "タスクがありません",
                        message: taskViewModel.selectedFilter == .completed ? "完了したタスクはまだありません" : "新しいタスクを作成しましょう"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(taskViewModel.filteredTasks) { task in
                                TaskCardView(
                                    task: Binding(
                                        get: {
                                            // 常に最新のタスクを取得
                                            taskViewModel.tasks.first(where: { $0.id == task.id }) ?? task
                                        },
                                        set: { updatedTask in
                                            taskViewModel.updateTask(updatedTask)
                                        }
                                    ),
                                    onComplete: { completedTask, photo in
                                        guard completedTask.status != .completed else { return }
                                        
                                        _Concurrency.Task { @MainActor in
                                            do {
                                                let photoURL = photo != nil ? "photo_\(completedTask.id)" : nil
                                                let result = try await taskViewModel.completeTask(completedTask, photoURL: photoURL)
                                                
                                                activityViewModel.recordTaskCompletion(
                                                    xpGained: result.xpGained,
                                                    totalTasksCount: taskViewModel.todayTasks.count
                                                )
                                                
                                                let leveledUp = activityViewModel.addXPToUser(result.xpGained)
                                                if leveledUp {
                                                    HapticManager.shared.levelUp()
                                                }
                                                
                                                let completedCount = taskViewModel.todayTasks.filter { $0.status == .completed }.count
                                                let epicIds = epicViewModel.epics.map(\.id)
                                                let epicProgress = taskViewModel.averageEpicProgress(epicIds: epicIds)
                                                activityViewModel.calculateActivityRing(
                                                    completedTasksCount: completedCount,
                                                    totalTasksCount: taskViewModel.todayTasks.count,
                                                    epicProgress: epicProgress
                                                )
                                                
                                                giftViewModel.checkAndUnlockGifts(
                                                    completedTask: result.completedTask,
                                                    taskViewModel: taskViewModel,
                                                    activityViewModel: activityViewModel
                                                )
                                            } catch {
                                                print("❌ エラー: \(error.localizedDescription)")
                                                taskViewModel.errorMessage = error.localizedDescription
                                            }
                                        }
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
                }
                .navigationTitle("タスク")
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .task {
                    await taskViewModel.loadTasks()
                }
                
                // FAB: タスク新規追加
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
        }
    }
}
// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("タスクを検索", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color(.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .cornerRadius(20)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    TaskListView()
        .environmentObject(TaskViewModel())
        .environmentObject(ActivityViewModel())
        .environmentObject(GiftViewModel())
        .environmentObject(EpicViewModel())
}

