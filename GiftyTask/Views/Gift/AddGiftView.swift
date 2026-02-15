import SwiftUI

// MARK: - ギフト条件選択（AddGiftView 用）
enum GiftConditionOption: String, CaseIterable {
    case epicCompletion = "健康習慣のエピック完了時"
    case taskCompletion = "特定のタスク完了時"
    case multipleTasksCompletion = "複数のタスク完了時"
    case streakDays = "タスクの継続達成時"
    
    func toUnlockCondition() -> UnlockCondition {
        switch self {
        case .epicCompletion:
            return UnlockCondition(conditionType: .epicCompletion, epicId: "epic-001")
        case .taskCompletion:
            return UnlockCondition(conditionType: .taskCompletion, taskId: "task-001")
        case .multipleTasksCompletion:
            return UnlockCondition(conditionType: .multipleTasksCompletion, taskIds: ["task-001", "task-002"])
        case .streakDays:
            return UnlockCondition(conditionType: .streakDays, streakDays: 7)
        }
    }
}

// MARK: - Add Gift View（ハーフモーダル・ギフト新規追加）
struct AddGiftView: View {
    @EnvironmentObject var giftViewModel: GiftViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    
    @State private var title: String = ""
    @State private var selectedCondition: GiftConditionOption = .epicCompletion
    @State private var priceText: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field { case title, price }
    
    private var priceValue: Double {
        Double(priceText.filter { $0.isNumber }) ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // タイトル（報酬名）
                    titleSection
                    
                    // 条件選択
                    conditionSection
                    
                    // 報酬の金額
                    priceSection
                    
                    Spacer(minLength: 20)
                    
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
            .navigationTitle("新規ギフト")
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
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("タイトル")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            TextField("例: スタバチケット、Amazonギフト券 1000円分", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 17))
                .padding(16)
                .focused($focusedField, equals: .title)
                .glassmorphism(cornerRadius: 14)
        }
    }
    
    private var conditionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("条件選択")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(GiftConditionOption.allCases, id: \.self) { option in
                    GiftConditionButton(
                        title: option.rawValue,
                        isSelected: selectedCondition == option
                    ) {
                        HapticManager.shared.selectionChanged()
                        selectedCondition = option
                    }
                }
            }
        }
    }
    
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("報酬の金額")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 0) {
                Text("¥")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                
                TextField("0", text: $priceText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17))
                    .padding(16)
                    .focused($focusedField, equals: .price)
            }
            .glassmorphism(cornerRadius: 14)
        }
    }
    
    private var saveButton: some View {
        Button(action: saveGift) {
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
        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || priceValue <= 0)
        .opacity(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || priceValue <= 0 ? 0.6 : 1)
    }
    
    private func saveGift() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, priceValue > 0 else { return }
        
        let condition = selectedCondition.toUnlockCondition()
        let (epicId, taskId) = (condition.epicId, condition.taskId)
        
        _ = giftViewModel.createGift(
            title: trimmedTitle,
            description: nil,
            price: priceValue,
            unlockCondition: condition,
            epicId: epicId,
            taskId: taskId
        )
        
        HapticManager.shared.mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            HapticManager.shared.successNotification()
        }
        
        isPresented = false
        dismiss()
    }
}

// MARK: - Gift Condition Button
private struct GiftConditionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    AddGiftView(isPresented: .constant(true))
        .environmentObject(GiftViewModel())
}
