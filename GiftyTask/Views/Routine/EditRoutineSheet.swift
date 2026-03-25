import SwiftUI

// MARK: - Edit Routine Sheet
struct EditRoutineSheet: View {
    @Binding var isPresented: Bool
    let routine: Routine
    @EnvironmentObject var routineViewModel: RoutineViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var rewardGiftTitle: String
    @State private var targetCount: Int
    @State private var showDeleteConfirm = false
    
    init(isPresented: Binding<Bool>, routine: Routine) {
        _isPresented = isPresented
        self.routine = routine
        _title = State(initialValue: routine.title)
        _description = State(initialValue: routine.description ?? "")
        _targetCount = State(initialValue: max(1, routine.targetCount))
        _rewardGiftTitle = State(initialValue: "")
    }
    
    private let primaryColor = Color(hex: "#4F46E5")
    
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
                    TextField("ご褒美（ギフト名）", text: $rewardGiftTitle)
                        .textContentType(.none)
                } header: {
                    Text("ご褒美（ギフト名）")
                } footer: {
                    Text("ギフトBOXに表示される名前です。未設定のルーティンでは名前を入れて保存するとギフトを新規作成して紐付けます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("目標達成日数") {
                    Stepper(value: $targetCount, in: 1...100) {
                        Text("\(targetCount) 日達成でギフト獲得")
                            .font(.body.weight(.medium))
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("削除")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("ルーティンを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRoutine()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canSave ? primaryColor : Color.secondary.opacity(0.5))
                    .disabled(!canSave)
                }
            }
            .alert("ルーティンを削除", isPresented: $showDeleteConfirm) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    deleteRoutine()
                }
            } message: {
                Text("このルーティンと紐付くご褒美ギフト（未使用）もリストから削除されます。")
            }
            .onAppear {
                syncRewardTitleFromGift()
            }
        }
    }
    
    private func syncRewardTitleFromGift() {
        guard !routine.associatedGiftId.isEmpty,
              let g = giftViewModel.gifts.first(where: { $0.id == routine.associatedGiftId }) else {
            return
        }
        rewardGiftTitle = g.title
    }
    
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveRoutine() {
        var updated = routine
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.description = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : description.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.targetCount = max(1, targetCount)
        
        let rewardTrimmed = rewardGiftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if updated.associatedGiftId.isEmpty {
            if !rewardTrimmed.isEmpty {
                let gift = giftViewModel.createRoutineRewardGift(
                    title: rewardTrimmed,
                    description: nil,
                    routineId: updated.id,
                    linkedRoutineTitle: updated.title
                )
                updated.associatedGiftId = gift.id
            }
        } else if var g = giftViewModel.gifts.first(where: { $0.id == updated.associatedGiftId }) {
            if !rewardTrimmed.isEmpty {
                g.title = rewardTrimmed
            }
            g.linkedTaskTitle = updated.title
            giftViewModel.updateGift(g)
        }
        
        routineViewModel.updateRoutine(updated)
        HapticManager.shared.successNotification()
        isPresented = false
    }
    
    private func deleteRoutine() {
        routineViewModel.deleteRoutine(id: routine.id)
        HapticManager.shared.mediumImpact()
        isPresented = false
    }
}
