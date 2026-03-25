import SwiftUI

// MARK: - Due Date Quick Option（今日/明日/今週/毎日/なし/日付指定）
enum DueDateQuickOption: String, CaseIterable {
    case today = "今日やる"
    case tomorrow = "明日やる"
    case thisWeek = "今週中"
    case daily = "毎日"
    case none = "期限なし"
    /// カードの「期限」がクイック候補に当てはまらないとき（編集時に実日付を保持）
    case pickDate = "日付を指定"
    
    func dueDate(calendar: Calendar = .current, pickedDate: Date = Date()) -> Date? {
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
        case .pickDate:
            return calendar.startOfDay(for: pickedDate)
        }
    }
    
    var isRoutine: Bool { self == .daily }
}

// MARK: - タスクカードと同じ表記（申告 / 写真）
private extension VerificationMode {
    var cardLabel: String {
        switch self {
        case .selfDeclaration: return "申告"
        case .photoEvidence: return "写真"
        }
    }
}

// MARK: - Add Task View (ハーフモーダル・タスク新規追加 / 編集)
struct AddTaskView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    var editingTask: Task? = nil
    var onDismiss: (() -> Void)? = nil
    
    @State private var taskTitle: String = ""
    @State private var taskDetail: String = ""
    @State private var selectedDueOption: DueDateQuickOption = .today
    @State private var selectedPriority: TaskPriority = .medium
    @State private var giftContent: String = ""
    @State private var selectedVerificationMode: VerificationMode = .selfDeclaration
    /// 「日付を指定」選択時の期限（カードは yyyy/MM/dd 表示と整合）
    @State private var pickedDueDate: Date = Date()
    @FocusState private var focusedField: Field?
    
    private let calendar = Calendar.current
    private let detailMaxLength = 30
    
    /// 編集時かつ「毎日」のときは「いつやる？」を他に変更不可
    private var isDueOptionLockedToDaily: Bool {
        editingTask?.isRoutine == true
    }
    
    enum Field { case title, detail, gift }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // カード表示順に合わせる: タイトル → ギフト名 → 詳細 → 期限 → 完了確認 → 優先度
                    taskNameSection
                    giftSection
                    detailSection
                    dueDateSection
                    verificationSection
                    prioritySection
                    editingMetaSection
                    
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
            .navigationTitle(editingTask != nil ? "タスクを編集" : "新規タスク")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        HapticManager.shared.selectionChanged()
                        isPresented = false
                        onDismiss?()
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let t = editingTask {
                taskTitle = t.title
                taskDetail = t.description ?? ""
                if let d = t.dueDate {
                    pickedDueDate = d
                }
                selectedDueOption = dueDateQuickOption(from: t)
                selectedPriority = t.priority
                giftContent = t.rewardDisplayName ?? ""
                selectedVerificationMode = t.verificationMode
            }
            focusedField = .title
        }
    }
    
    private func dueDateQuickOption(from task: Task) -> DueDateQuickOption {
        if task.isRoutine { return .daily }
        guard let d = task.dueDate else { return .none }
        let today = calendar.startOfDay(for: Date())
        let taskDay = calendar.startOfDay(for: d)
        if calendar.isDate(taskDay, inSameDayAs: today) { return .today }
        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: today),
           calendar.isDate(taskDay, inSameDayAs: tomorrow) { return .tomorrow }
        if let weekEnd = DueDateQuickOption.thisWeek.dueDate(calendar: calendar, pickedDate: Date()),
           taskDay <= weekEnd, taskDay >= today { return .thisWeek }
        return .pickDate
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
    
    // MARK: - 詳細（カードの説明文に対応）
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細（任意）")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("タスクカードに表示される補足", text: $taskDetail)
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
    
    // MARK: - 期限（カードのカレンダー行に対応）
    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("期限")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            FlowLayout(spacing: 10) {
                ForEach(DueDateQuickOption.allCases, id: \.self) { option in
                    let isDisabled = isDueOptionLockedToDaily && option != .daily
                    QuickOptionButton(
                        title: option.rawValue,
                        isSelected: selectedDueOption == option,
                        isDisabled: isDisabled
                    ) {
                        if isDueOptionLockedToDaily && option != .daily { return }
                        HapticManager.shared.selectionChanged()
                        selectedDueOption = option
                    }
                }
            }
            if selectedDueOption == .pickDate {
                DatePicker(
                    "日付",
                    selection: $pickedDueDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - 優先度（カード右上の色と対応）
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
    
    // MARK: - ギフト名（カードの 🎁 行に対応）
    private var giftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ギフト（報酬名）")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("例: スタバチケット（タイトル下に表示）", text: $giftContent)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .padding(16)
                .focused($focusedField, equals: .gift)
                .glassmorphism(cornerRadius: 14)
        }
    }
    
    // MARK: - 完了の確認（カードの「申告」「写真」に対応）
    private var verificationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("完了の確認")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                ForEach([VerificationMode.selfDeclaration, .photoEvidence], id: \.self) { mode in
                    QuickOptionButton(
                        title: mode.cardLabel,
                        isSelected: selectedVerificationMode == mode
                    ) {
                        HapticManager.shared.selectionChanged()
                        selectedVerificationMode = mode
                    }
                }
            }
        }
    }
    
    /// 編集時のみ: カードの作成者・進捗行（読み取り専用）
    @ViewBuilder
    private var editingMetaSection: some View {
        if let t = editingTask {
            let creator = t.createdByUserName ?? t.senderName ?? t.fromDisplayName
            let showCreator = !(creator ?? "").isEmpty
            let showProgress = t.isTargetDaysTask
            if showCreator || showProgress {
                VStack(alignment: .leading, spacing: 12) {
                    Text("カードの表示")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    if showCreator, let name = creator, !name.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Text("作成者")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(name)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                    }
                    if showProgress {
                        Text("進捗: \(t.currentCount)/\(t.targetDays)（届いたタスクの目標日数は送信時の設定に基づきます）")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
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
        
        let dueDate = selectedDueOption.dueDate(calendar: calendar, pickedDate: pickedDueDate)
        let description = taskDetail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : String(taskDetail.prefix(detailMaxLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        let rewardName = giftContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : giftContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existing = editingTask {
            var updated = existing
            updated.title = title
            updated.description = description
            updated.priority = selectedPriority
            updated.dueDate = dueDate
            updated.verificationMode = selectedVerificationMode
            updated.rewardDisplayName = rewardName
            updated.isRoutine = selectedDueOption.isRoutine
            updated.updatedAt = Date()
            taskViewModel.updateTask(updated)
        } else {
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
        }
        
        HapticManager.shared.mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticManager.shared.successNotification()
        }
        
        isPresented = false
        onDismiss?()
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
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(foregroundColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
    
    private var foregroundColor: Color {
        if isDisabled { return .secondary }
        return isSelected ? .white : .primary
    }
    
    private var backgroundColor: Color {
        if isDisabled { return Color(.systemGray5) }
        return isSelected ? Color.accentColor : Color(.systemGray6)
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
    /// 未指定ならアプリのアクセント色（タスク用）。ギフト用は .orange などを指定。
    var tint: Color = Color.accentColor
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(tint)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                .shadow(color: tint.opacity(0.4), radius: 4, x: 0, y: 2)
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
