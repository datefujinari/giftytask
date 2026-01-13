import SwiftUI

// MARK: - Task List View
struct TaskListView: View {
    @State private var tasks: [Task]
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    
    enum TaskFilter: String, CaseIterable {
        case all = "全て"
        case pending = "未完了"
        case completed = "完了"
        case today = "今日"
    }
    
    init(tasks: [Task] = PreviewContainer.mockTasks) {
        _tasks = State(initialValue: tasks)
    }
    
    var filteredTasks: [Task] {
        var result = tasks
        
        // フィルタリング
        switch selectedFilter {
        case .all:
            break
        case .pending:
            result = result.filter { $0.status != .completed && $0.status != .archived }
        case .completed:
            result = result.filter { $0.status == .completed }
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            result = result.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDate(dueDate, inSameDayAs: today)
            }
        }
        
        // 検索
        if !searchText.isEmpty {
            result = result.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 検索バー
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // フィルタ
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // タスク一覧
                if filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: "タスクがありません",
                        message: selectedFilter == .completed ? "完了したタスクはまだありません" : "新しいタスクを作成しましょう"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredTasks) { task in
                                TaskCardView(
                                    task: task,
                                    onComplete: { completedTask, photo in
                                        if let index = tasks.firstIndex(where: { $0.id == completedTask.id }) {
                                            tasks[index] = completedTask
                                        }
                                        HapticManager.shared.taskCompleted()
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

// MARK: - Preview
#Preview {
    TaskListView(tasks: PreviewContainer.mockTasks)
}

