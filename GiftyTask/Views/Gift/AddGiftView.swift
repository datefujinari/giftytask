import SwiftUI

// MARK: - ギフト作成ステップ
enum AddGiftStep: Int, CaseIterable {
    case basic = 0    // 基本情報
    case condition = 1 // 条件設定
    case confirm = 2   // 最終確認
}

// MARK: - Add Gift View（3ステップ・ハーフモーダル）
struct AddGiftView: View {
    @EnvironmentObject var giftViewModel: GiftViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var epicViewModel: EpicViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    var editingGift: Gift? = nil
    
    @State private var step: AddGiftStep = .basic
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var conditionType: UnlockCondition.ConditionType = .epicCompletion
    @State private var selectedTargetIds: [String] = []
    @State private var selectedStreakDays: Int = 7
    @State private var rewardUrlText: String = ""
    @State private var priceText: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field { case title, description, rewardUrl, price }
    
    private var priceValue: Double {
        Double(priceText.filter { $0.isNumber }) ?? 0
    }
    
    private var isEditing: Bool { editingGift != nil }
    
    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .basic: step1Basic
                case .condition: step2Condition
                case .confirm: step3Confirm
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.06), Color.purple.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle(isEditing ? "条件を編集" : stepTitle)
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
                if step != .basic {
                    ToolbarItem(placement: .primaryAction) {
                        Button("戻る") {
                            step = AddGiftStep(rawValue: step.rawValue - 1) ?? .basic
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let g = editingGift {
                title = g.title
                description = g.description ?? ""
                conditionType = normalizeConditionType(g.unlockCondition.conditionType)
                selectedTargetIds = g.unlockCondition.targetIds
                selectedStreakDays = g.unlockCondition.streakDays ?? 7
                rewardUrlText = g.rewardUrl ?? ""
                priceText = g.price > 0 ? "\(Int(g.price))" : ""
            }
            focusedField = .title
        }
    }
    
    private var stepTitle: String {
        switch step {
        case .basic: return "新規ギフト（1/3）"
        case .condition: return "新規ギフト（2/3）"
        case .confirm: return "新規ギフト（3/3）"
        }
    }
    
    // MARK: - ステップ1: 基本情報
    private var step1Basic: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("タイトル（報酬名）")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("例: スタバチケット、Amazonギフト券", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17))
                        .padding(16)
                        .focused($focusedField, equals: .title)
                        .glassmorphism(cornerRadius: 14)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("詳細説明")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("補足（任意）", text: $description)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .padding(16)
                        .focused($focusedField, equals: .description)
                        .glassmorphism(cornerRadius: 14)
                }
                Spacer(minLength: 20)
                nextButton(title: "次へ") {
                    step = .condition
                }
            }
        }
    }
    
    // MARK: - ステップ2: 条件設定
    private var step2Condition: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("条件")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    Menu {
                        ForEach([UnlockCondition.ConditionType.epicCompletion, .singleTask, .multipleTasks, .streak], id: \.self) { type in
                            Button(UnlockCondition.displayName(for: type)) {
                                conditionType = type
                                selectedTargetIds = []
                            }
                        }
                    } label: {
                        HStack {
                            Text(UnlockCondition.displayName(for: conditionType))
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                        .padding(16)
                        .glassmorphism(cornerRadius: 14)
                    }
                }
                
                targetSelectionView
                
                if conditionType == .streak {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("継続日数")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        Stepper("\(selectedStreakDays) 日", value: $selectedStreakDays, in: 1...365)
                            .padding(16)
                            .glassmorphism(cornerRadius: 14)
                    }
                }
                
                Spacer(minLength: 20)
                nextButton(title: "次へ") {
                    step = .confirm
                }
            }
        }
    }
    
    @ViewBuilder
    private var targetSelectionView: some View {
        switch conditionType {
        case .epicCompletion:
            epicPicker
        case .singleTask, .taskCompletion:
            singleTaskPicker
        case .multipleTasks, .multipleTasksCompletion:
            multipleTasksPicker
        case .streak, .streakDays:
            routineTaskPicker
        case .xpThreshold:
            EmptyView()
        }
    }
    
    private var epicPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("対象エピック")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            let epics = epicViewModel.epics.filter { epic in
                let tasks = taskViewModel.getTasks(for: epic.id)
                return !tasks.isEmpty && !tasks.allSatisfy { $0.status == .completed }
            }
            ForEach(epics.isEmpty ? epicViewModel.epics : epics) { epic in
                Button {
                    selectedTargetIds = [epic.id]
                } label: {
                    HStack {
                        Text(epic.title).foregroundColor(.primary)
                        Spacer()
                        if selectedTargetIds.contains(epic.id) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                        }
                    }
                    .padding(14)
                    .glassmorphism(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var singleTaskPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("対象タスク")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            let tasks = taskViewModel.tasks.filter { $0.status != .completed }
            ForEach(tasks.prefix(50)) { task in
                Button {
                    selectedTargetIds = [task.id]
                } label: {
                    HStack {
                        Text(task.title).foregroundColor(.primary).lineLimit(1)
                        Spacer()
                        if selectedTargetIds.contains(task.id) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                        }
                    }
                    .padding(14)
                    .glassmorphism(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var multipleTasksPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("対象タスク（最大10個）")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            let tasks = taskViewModel.tasks.filter { $0.status != .completed }
            ForEach(tasks.prefix(50)) { task in
                Button {
                    toggleMultipleSelection(task.id)
                } label: {
                    HStack {
                        Text(task.title).foregroundColor(.primary).lineLimit(1)
                        Spacer()
                        if selectedTargetIds.contains(task.id) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                        }
                    }
                    .padding(14)
                    .glassmorphism(cornerRadius: 12)
                }
                .buttonStyle(.plain)
                .disabled(selectedTargetIds.count >= 10 && !selectedTargetIds.contains(task.id))
            }
        }
    }
    
    private var routineTaskPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("毎日タスク（1つ選択）")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            let routineTasks = taskViewModel.tasks.filter { $0.isRoutine }
            ForEach(routineTasks.isEmpty ? Array(taskViewModel.tasks.prefix(20)) : routineTasks) { task in
                Button {
                    selectedTargetIds = [task.id]
                } label: {
                    HStack {
                        Text(task.title).foregroundColor(.primary).lineLimit(1)
                        Spacer()
                        if selectedTargetIds.contains(task.id) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.accentColor)
                        }
                    }
                    .padding(14)
                    .glassmorphism(cornerRadius: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func toggleMultipleSelection(_ id: String) {
        if selectedTargetIds.contains(id) {
            selectedTargetIds.removeAll { $0 == id }
        } else if selectedTargetIds.count < 10 {
            selectedTargetIds.append(id)
        }
    }
    
    // MARK: - ステップ3: 最終確認
    private var step3Confirm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("リンク先URL（任意）")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    TextField("https://", text: $rewardUrlText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .padding(16)
                        .focused($focusedField, equals: .rewardUrl)
                        .glassmorphism(cornerRadius: 14)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("金額（円）")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 0) {
                        Text("¥")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                        TextField("0", text: $priceText)
                            .keyboardType(.numberPad)
                            .padding(16)
                            .focused($focusedField, equals: .price)
                    }
                    .glassmorphism(cornerRadius: 14)
                }
                Spacer(minLength: 20)
                if isEditing {
                    saveEditButton
                } else {
                    createButton
                }
            }
        }
    }
    
    private func nextButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.selectionChanged()
            action()
        }) {
            HStack {
                Spacer()
                Text(title)
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
        }
        .buttonStyle(.plain)
    }
    
    private var createButton: some View {
        Button(action: saveNewGift) {
            HStack {
                Spacer()
                Text("作成")
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
        }
        .buttonStyle(.plain)
        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || priceValue <= 0)
        .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || priceValue <= 0 ? 0.6 : 1)
    }
    
    private var saveEditButton: some View {
        Button(action: saveEditedGift) {
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
        }
        .buttonStyle(.plain)
    }
    
    private func saveNewGift() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, priceValue > 0 else { return }
        
        let cond = UnlockCondition(
            conditionType: conditionType,
            targetIds: selectedTargetIds,
            streakDays: (conditionType == .streak || conditionType == .streakDays) ? selectedStreakDays : nil
        )
        let rewardUrl = rewardUrlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : rewardUrlText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        _ = giftViewModel.createGift(
            title: trimmedTitle,
            description: description.isEmpty ? nil : description,
            price: priceValue,
            unlockCondition: cond,
            rewardUrl: rewardUrl
        )
        
        HapticManager.shared.mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticManager.shared.successNotification()
        }
        isPresented = false
        dismiss()
    }
    
    private func saveEditedGift() {
        guard var gift = editingGift else { return }
        gift.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        gift.description = description.isEmpty ? nil : description
        gift.price = priceValue
        gift.rewardUrl = rewardUrlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : rewardUrlText.trimmingCharacters(in: .whitespacesAndNewlines)
        gift.unlockCondition = UnlockCondition(
            conditionType: conditionType,
            targetIds: selectedTargetIds,
            streakDays: (conditionType == .streak || conditionType == .streakDays) ? selectedStreakDays : nil
        )
        giftViewModel.updateGift(gift)
        HapticManager.shared.successNotification()
        isPresented = false
        dismiss()
    }
    
    private func normalizeConditionType(_ t: UnlockCondition.ConditionType) -> UnlockCondition.ConditionType {
        switch t {
        case .taskCompletion: return .singleTask
        case .multipleTasksCompletion: return .multipleTasks
        case .streakDays: return .streak
        default: return t
        }
    }
}

// MARK: - GiftViewModel.createGift 拡張（rewardUrl / targetIds 対応）
extension GiftViewModel {
    func createGift(
        title: String,
        description: String? = nil,
        price: Double,
        unlockCondition: UnlockCondition,
        epicId: String? = nil,
        taskId: String? = nil,
        rewardUrl: String? = nil
    ) -> Gift {
        let epic = unlockCondition.conditionType == .epicCompletion ? unlockCondition.targetIds.first : nil
        let task = (unlockCondition.conditionType == .singleTask || unlockCondition.conditionType == .taskCompletion || unlockCondition.conditionType == .streak) ? unlockCondition.targetIds.first : nil
        let gift = Gift(
            title: title,
            description: description,
            status: .locked,
            type: .selfReward,
            unlockCondition: unlockCondition,
            epicId: epic ?? epicId,
            taskId: task ?? taskId,
            price: price,
            currency: "JPY",
            rewardUrl: rewardUrl,
            currentStreak: 0
        )
        gifts.append(gift)
        saveData()
        return gift
    }
}

// MARK: - Preview
#Preview {
    AddGiftView(isPresented: .constant(true))
        .environmentObject(GiftViewModel())
        .environmentObject(TaskViewModel())
        .environmentObject(ActivityViewModel())
        .environmentObject(EpicViewModel())
}
