import SwiftUI

/// タスク + ギフトの統一入力画面
struct CreateAssignmentView: View {
    enum Destination: String, CaseIterable, Identifiable {
        case myself = "自分用"
        case send = "相手に送る"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    @ObservedObject private var taskRepo = TaskRepository.shared
    @ObservedObject private var authManager = AuthManager.shared

    @Binding var isPresented: Bool

    @State private var destination: Destination = .myself
    @State private var receiverId: String = ""
    @State private var targetDays: Int = 1
    @State private var addToFriendList = true

    @State private var taskTitle: String = ""
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = true
    @State private var selectedPriority: TaskPriority = .medium
    @State private var selectedVerificationMode: VerificationMode = .selfDeclaration

    @State private var giftName: String = ""
    @State private var giftDescription: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private let giftDescriptionMaxLength = 40

    private var friendList: [String] {
        authManager.userProfile?.friendList ?? []
    }

    private var canSave: Bool {
        let trimmedTaskTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGiftName = giftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReceiver = receiverId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTaskTitle.isEmpty, !trimmedGiftName.isEmpty else { return false }
        switch destination {
        case .myself:
            return true
        case .send:
            return !trimmedGiftName.isEmpty && !trimmedReceiver.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                destinationSection
                if destination == .send {
                    receiverSection
                }
                taskSection
                giftSection
                saveSection
            }
            .navigationTitle("タスクを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        isPresented = false
                        dismiss()
                    }
                }
            }
            .alert("保存しました", isPresented: $showSuccess) {
                Button("OK") {
                    isPresented = false
                    dismiss()
                }
            } message: {
                Text(destination == .send ? "タスクを送信しました。" : "タスクとギフトを保存しました。")
            }
        }
        .onChange(of: giftDescription) { _, newValue in
            if newValue.count > giftDescriptionMaxLength {
                giftDescription = String(newValue.prefix(giftDescriptionMaxLength))
            }
        }
    }

    private var destinationSection: some View {
        Section("作成先") {
            Picker("作成先", selection: $destination) {
                ForEach(Destination.allCases) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var receiverSection: some View {
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

            Picker("目標日数", selection: $targetDays) {
                ForEach(1...30, id: \.self) { day in
                    Text("\(day)日").tag(day)
                }
            }

            Toggle("フレンドに追加する", isOn: $addToFriendList)
                .disabled(receiverId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var taskSection: some View {
        Section("タスク情報") {
            TextField("タスク名（必須）", text: $taskTitle)

            Toggle("期限を設定する", isOn: $hasDueDate)
            if hasDueDate {
                DatePicker("期限", selection: $dueDate, displayedComponents: .date)
            }

            Picker("達成条件", selection: $selectedVerificationMode) {
                Text("自己申告").tag(VerificationMode.selfDeclaration)
                Text("証拠写真").tag(VerificationMode.photoEvidence)
            }

            Picker("優先度", selection: $selectedPriority) {
                Text(TaskPriority.low.displayName).tag(TaskPriority.low)
                Text(TaskPriority.medium.displayName).tag(TaskPriority.medium)
                Text(TaskPriority.high.displayName).tag(TaskPriority.high)
                Text(TaskPriority.urgent.displayName).tag(TaskPriority.urgent)
            }
        }
    }

    private var giftSection: some View {
        Section("ギフト情報") {
            TextField("ギフト名（必須）", text: $giftName)
            TextField("詳細（40文字以内）", text: $giftDescription, axis: .vertical)
            Text("\(giftDescription.count)/\(giftDescriptionMaxLength)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var saveSection: some View {
        Section {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button {
                _Concurrency.Task { @MainActor in
                    await save()
                }
            } label: {
                HStack {
                    Spacer()
                    if isSaving {
                        ProgressView()
                    } else {
                        Text(destination == .send ? "送信する" : "保存する")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(!canSave || isSaving)
        }
    }

    private func save() async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }

        let trimmedTaskTitle = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGiftName = giftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGiftDescription = giftDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDueDate = hasDueDate ? Calendar.current.startOfDay(for: dueDate) : nil

        do {
            switch destination {
            case .myself:
                let createdTask = taskViewModel.createTask(
                    title: trimmedTaskTitle,
                    description: nil,
                    epicId: nil,
                    verificationMode: selectedVerificationMode,
                    priority: selectedPriority,
                    dueDate: normalizedDueDate,
                    xpReward: 10,
                    rewardDisplayName: trimmedGiftName,
                    isRoutine: false
                )

                let condition = UnlockCondition(conditionType: .singleTask, targetIds: [createdTask.id])
                _ = giftViewModel.createGift(
                    title: trimmedGiftName,
                    description: trimmedGiftDescription.isEmpty ? nil : trimmedGiftDescription,
                    price: 0,
                    unlockCondition: condition,
                    taskId: createdTask.id,
                    linkedTaskTitle: createdTask.title,
                    linkedTaskDueDate: createdTask.dueDate
                )
            case .send:
                let receiver = receiverId.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = try await taskRepo.sendTask(
                    title: trimmedTaskTitle,
                    giftName: trimmedGiftName,
                    receiverId: receiver,
                    targetDays: targetDays,
                    dueDate: normalizedDueDate,
                    giftDescription: trimmedGiftDescription.isEmpty ? nil : String(trimmedGiftDescription.prefix(giftDescriptionMaxLength))
                )
                if addToFriendList, !receiver.isEmpty {
                    try? await authManager.addFriend(receiver)
                }
                if let receiverProfile = await AuthManager.shared.fetchOtherUserProfile(uid: receiver) {
                    NotificationService.notifyTaskReceived(
                        receiverFCMToken: receiverProfile.fcmToken,
                        senderDisplayName: authManager.userProfile?.displayName ?? "ユーザー"
                    )
                }
            }

            HapticManager.shared.successNotification()
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CreateAssignmentView(isPresented: .constant(true))
        .environmentObject(TaskViewModel())
        .environmentObject(GiftViewModel())
}
