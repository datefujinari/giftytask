import SwiftUI

// MARK: - Add Routine Sheet
struct AddRoutineSheet: View {
    enum Destination: String, CaseIterable, Identifiable {
        case myself = "自分用"
        case send = "相手に送る"
        var id: String { rawValue }
    }
    
    @Binding var isPresented: Bool
    @EnvironmentObject var routineViewModel: RoutineViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    @ObservedObject private var taskRepo = TaskRepository.shared
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var title = ""
    @State private var description = ""
    /// ご褒美としてギフトBOXに追加される名前
    @State private var rewardGiftTitle = ""
    @State private var targetCount = 7
    @State private var destination: Destination = .myself
    @State private var receiverId = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    private let primaryColor = Color(hex: "#4F46E5")
    
    private var friendList: [String] {
        authManager.userProfile?.friendList ?? []
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("作成先") {
                    Picker("作成先", selection: $destination) {
                        ForEach(Destination.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if destination == .send {
                    Section("送信先") {
                        if !friendList.isEmpty {
                            Picker("フレンドから選ぶ", selection: $receiverId) {
                                Text("選択してください").tag("")
                                ForEach(friendList, id: \.self) { uid in
                                    Text(uid).tag(uid)
                                }
                            }
                        }
                        
                        TextField("相手のユーザーID（UID）", text: $receiverId)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                
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
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("ルーティンを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                    .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        _Concurrency.Task { @MainActor in
                            await addRoutine()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(canAdd ? primaryColor : Color.secondary.opacity(0.5))
                    .disabled(!canAdd || isSaving)
                }
            }
            .alert("送信しました", isPresented: $showSuccess) {
                Button("OK") { isPresented = false }
            } message: {
                Text("ルーティン提案を送信しました。")
            }
        }
    }
    
    private var canAdd: Bool {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let g = rewardGiftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if destination == .send {
            return !t.isEmpty && !g.isEmpty && !receiverId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return !t.isEmpty && !g.isEmpty
    }
    
    private func addRoutine() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReward = rewardGiftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDesc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            switch destination {
            case .myself:
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
            case .send:
                _ = try await taskRepo.sendRoutineSuggestion(
                    title: trimmedTitle,
                    description: trimmedDesc.isEmpty ? nil : trimmedDesc,
                    targetCount: max(1, targetCount),
                    associatedGiftName: trimmedReward,
                    receiverId: receiverId.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                HapticManager.shared.successNotification()
                showSuccess = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
