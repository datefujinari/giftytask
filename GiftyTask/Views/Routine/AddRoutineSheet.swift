import SwiftUI

// MARK: - Add Routine Sheet
struct AddRoutineSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var routineViewModel: RoutineViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    
    @State private var title = ""
    @State private var description = ""
    /// ご褒美としてギフトBOXに追加される名前
    @State private var rewardGiftTitle = ""
    @State private var targetCount = 7
    
    private let primaryColor = Color(hex: "#4F46E5")
    private let secondaryColor = Color(hex: "#6B7280")
    
    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("ルーティン名（必須）", text: $title)
                        .textContentType(.none)
                }
                
                Section("説明") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }
                
                Section {
                    TextField("ご褒美（ギフト名・必須）", text: $rewardGiftTitle)
                        .textContentType(.none)
                } header: {
                    Text("ご褒美（ギフト名）")
                } footer: {
                    Text("保存時にギフトBOXへロック済みギフトとして追加され、累積達成で解禁されます。")
                        .font(.caption)
                        .foregroundColor(secondaryColor)
                }
                
                Section {
                    Stepper(value: $targetCount, in: 1...100) {
                        Text("\(targetCount) 日達成でギフト獲得")
                            .font(.body.weight(.medium))
                    }
                } header: {
                    Text("目標達成日数")
                } footer: {
                    Text("例: 7日・10日・30日など。毎日完了すると1日ずつカウントされます。")
                        .font(.caption)
                        .foregroundColor(secondaryColor)
                }
            }
            .navigationTitle("ルーティンを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .foregroundColor(secondaryColor)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addRoutine()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canAdd ? primaryColor : secondaryColor.opacity(0.5))
                    .disabled(!canAdd)
                }
            }
        }
    }
    
    private var canAdd: Bool {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let g = rewardGiftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return !t.isEmpty && !g.isEmpty
    }
    
    private func addRoutine() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReward = rewardGiftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let routineId = UUID()
        let gift = giftViewModel.createRoutineRewardGift(
            title: trimmedReward,
            description: nil,
            routineId: routineId,
            linkedRoutineTitle: trimmedTitle
        )
        let routine = Routine(
            id: routineId,
            title: trimmedTitle,
            description: trimmedDesc.isEmpty ? nil : trimmedDesc,
            associatedGiftId: gift.id,
            targetCount: max(1, targetCount),
            currentCycleCount: 0
        )
        routineViewModel.addRoutine(routine)
        HapticManager.shared.successNotification()
        isPresented = false
    }
}
