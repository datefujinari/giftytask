import SwiftUI

// MARK: - Due Date Quick Option（今日/明日/今週/毎日/なし）
enum DueDateQuickOption: String, CaseIterable {
    case today = "今日やる"
    case tomorrow = "明日やる"
    case thisWeek = "今週中"
    case daily = "毎日"
    case none = "期限なし"
    
    func dueDate(calendar: Calendar = .current) -> Date? {
        let now = Date()
        let today = calendar.startOfDay(for: now)
        switch self {
        case .today:
            return today
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: today)
        case .thisWeek:
            guard let weekday = calendar.dateComponents([.weekday], from: now).weekday else { return nil }
            let daysUntilSaturday = weekday == 7 ? 0 : (7 - weekday)
            return calendar.date(byAdding: .day, value: daysUntilSaturday, to: today)
        case .daily:
            return today // 毎日は「今日」として表示し、isRoutine でルーチン扱い
        case .none:
            return nil
        }
    }
    
    var isRoutine: Bool { self == .daily }
}

// MARK: - Verification Mode Display
private extension VerificationMode {
    var displayName: String {
        switch self {
        case .selfDeclaration: return "自己申告"
        case .photoEvidence: return "証拠写真"
        }
    }
}

// MARK: - Add Task View (ハーフモーダル・タスク新規追加)
struct AddTaskView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var taskTitle: String = ""
    @State private var taskDetail: String = ""       // 詳細（30文字程度）
    @State private var selectedDueOption: DueDateQuickOption = .today
    @State private var selectedPriority: TaskPriority = .medium
    @State private var giftContent: String = ""     // 達成時に解禁したい報酬名
    @State private var selectedVerificationMode: VerificationMode = .selfDeclaration
    @FocusState private var focusedField: Field?
    
    private let calendar = Calendar.current
    private let detailMaxLength = 30
    
    enum Field { case title, detail, gift }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 1. タスク名
                    taskNameSection
                    
                    // 2. 詳細の記入
                    detailSection
                    
                    // 3. いつやる？
                    dueDateSection
                    
                    // 4. 優先度
                    prioritySection
                    
                    // 5. Giftの内容
                    giftSection
                    
                    // 6. 達成の条件
                    verificationSection
                    
                    Spacer(minLength: 20)
                    
                    // 保存ボタン
                    saveButton
                }
                .padding(24)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("新規タスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        HapticManager.shared.selectionChanged()
                        isPresented = false
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear { focusedField = .title }
    }
    
    // MARK: - 1. タスク名
    private var taskNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タスク名")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("例: 朝のジョギング", text: $taskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .padding(16)
                .focused($focusedField, equals: .title)
                .glassmorphism(cornerRadius: 14)
        }
    }
    
    // MARK: - 2. 詳細の記入（30文字程度）
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細の記入")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("補足情報（任意）", text: $taskDetail)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .padding(12)
                .focused($focusedField, equals: .detail)
                .glassmorphism(cornerRadius: 12)
                .onChange(of: taskDetail) { _, newValue in
                    if newValue.count > detailMaxLength {
                        taskDetail = String(newValue.prefix(detailMaxLength))
                    }
                }
            
            Text("\(taskDetail.count)/\(detailMaxLength)")
                .font(.system(size: 11))
                .foregroundColor(Color(.tertiaryLabel))
        }
    }
    
    // MARK: - 3. いつやる？（今日/明日/今週/毎日/なし）
    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("いつやる？")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 10) {
                ForEach(DueDateQuickOption.allCases, id: \.self) { option in
                    QuickOptionButton(
                        title: option.rawValue,
                        isSelected: selectedDueOption == option
                    ) {
                        HapticManager.shared.selectionChanged()
                        selectedDueOption = option
                    }
                }
            }
        }
    }
    
    // MARK: - 4. 優先度
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("優先度")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                ForEach([TaskPriority.low, .medium, .high, .urgent], id: \.self) { priority in
                    PriorityChip(
                        priority: priority,
                        isSelected: selectedPriority == priority
                    ) {
                        HapticManager.shared.selectionChanged()
                        selectedPriority = priority
                    }
                }
            }
        }
    }
    
    // MARK: - 5. Giftの内容
    private var giftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Giftの内容")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("達成時に解禁したい報酬名（任意）", text: $giftContent)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .padding(16)
                .focused($focusedField, equals: .gift)
                .glassmorphism(cornerRadius: 14)
        }
    }
    
    // MARK: - 6. 達成の条件（自己申告 / 証拠写真）
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("達成の条件")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                ForEach([VerificationMode.selfDeclaration, .photoEvidence], id: \.self) { mode in
                    QuickOptionButton(
                        title: mode.displayName,
                        isSelected: selectedVerificationMode == mode
                    ) {
                        HapticManager.shared.selectionChanged()
                        selectedVerificationMode = mode
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button(action: saveTask) {
            HStack {
                Spacer()
                Text("保存")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.accentColor.opacity(0.35), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
    }
    
    private func saveTask() {
        let title = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        
        let dueDate = selectedDueOption.dueDate(calendar: calendar)
        let description = taskDetail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : String(taskDetail.prefix(detailMaxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        let rewardName = giftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : giftContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        _ = taskViewModel.createTask(
            title: title,
            description: description,
            epicId: nil,
            verificationMode: selectedVerificationMode,
            priority: selectedPriority,
            dueDate: dueDate,
            xpReward: 10,
            rewardDisplayName: rewardName,
            isRoutine: selectedDueOption.isRoutine
        )
        
        HapticManager.shared.mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticManager.shared.successNotification()
        }
        
        isPresented = false
        dismiss()
    }
}

// MARK: - Flow Layout（クイックボタンが複数行に折り返す用）
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, pos) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Quick Option Button
private struct QuickOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Priority Chip
private struct PriorityChip: View {
    let priority: TaskPriority
    let isSelected: Bool
    let action: () -> Void
    
    private var chipColor: Color {
        switch priority {
        case .low: return .blue
        case .medium: return .green
        case .high: return .orange
        case .urgent: return .red
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(priority.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : chipColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? chipColor : chipColor.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Task FAB (Floating Action Button)
struct AddTaskFAB: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                .shadow(color: Color.accentColor.opacity(0.4), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    AddTaskView(isPresented: .constant(true))
        .environmentObject(TaskViewModel())
        .environmentObject(ActivityViewModel())
}
