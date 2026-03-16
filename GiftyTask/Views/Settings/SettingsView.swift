import SwiftUI

// MARK: - 設定画面（プロフィール編集・UID表示・コピー・累計達成数・承認待ち・テスト通知）
struct SettingsView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showCopiedFeedback = false
    @State private var editingDisplayName = ""
    @State private var isSavingProfile = false
    @State private var profileSaveMessage: String?
    @State private var showApprovalPending = false
    @State private var testNotificationScheduled = false
    @State private var lastTestNotificationInfo: String?
    
    private var currentUID: String {
        authManager.currentUser?.uid ?? "未ログイン"
    }
    
    private var pendingApprovalCount: Int {
        taskViewModel.pendingApprovalTasks.count
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 承認待ち・テスト通知
                Section {
                    Button {
                        showApprovalPending = true
                    } label: {
                        HStack {
                            Label("承認待ち", systemImage: "checkmark.circle.fill")
                            if pendingApprovalCount > 0 {
                                Spacer()
                                Text("\(pendingApprovalCount)件")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Button {
                        NotificationService.scheduleTestNotification(delaySeconds: 5)
                        HapticManager.shared.mediumImpact()
                        testNotificationScheduled = true
                        let formatter = DateFormatter()
                        formatter.dateFormat = "HH:mm:ss"
                        lastTestNotificationInfo = "テスト通知を \(formatter.string(from: Date().addingTimeInterval(5))) 頃に予約しました"
                        _Concurrency.Task { @MainActor in
                            try? await _Concurrency.Task.sleep(nanoseconds: 8_000_000_000)
                            testNotificationScheduled = false
                        }
                    } label: {
                        HStack {
                            Label("テスト通知を送る", systemImage: "bell.badge")
                            if testNotificationScheduled {
                                Spacer()
                                Text("スケジュール済み…")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    if let info = lastTestNotificationInfo {
                        Text(info)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("通知・承認")
                } footer: {
                    Text("「テスト通知を送る」を押すと5秒後にローカル通知が届きます。AppDelegate が通知を正しく表示しているか確認できます。")
                }
                
                // プロフィール編集
                Section {
                    TextField("ニックネーム", text: $editingDisplayName)
                        .textContentType(.nickname)
                        .autocapitalization(.words)
                    if isSavingProfile {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        Button {
                            _Concurrency.Task { @MainActor in
                                await saveProfile()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Text("プロフィールを保存")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .background(canSaveProfile ? Color.accentColor : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!canSaveProfile)
                    }
                    if let msg = profileSaveMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundColor(msg.contains("失敗") ? .red : .green)
                    }
                    if authManager.currentUser != nil, let saved = authManager.userProfile?.displayName {
                        HStack {
                            Text("保存済みの表示名")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(saved)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .font(.caption)
                    }
                } header: {
                    Text("プロフィール")
                }
                
                // UID と累計達成数
                Section {
                    HStack {
                        Text("ユーザーID（UID）")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(currentUID)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        copyUIDToPasteboard()
                    }
                    if authManager.currentUser != nil {
                        HStack {
                            Text("累計達成数")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(authManager.userProfile?.totalCompletedCount ?? 0) 件")
                                .font(.headline)
                                .foregroundColor(.accentColor)
                        }
                        Text("タップでUIDをコピー")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("自分のユーザーID")
                } footer: {
                    Text("相手にタスクを送る際、相手のUIDの入力が必要です。このIDを相手に伝えるか、相手のUIDを入力してタスクを送信してください。")
                }
                if showCopiedFeedback {
                    Section {
                        Label("コピーしました", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                editingDisplayName = authManager.userProfile?.displayName ?? "ユーザー"
            }
            .onChange(of: authManager.userProfile?.displayName) { _, newValue in
                if let v = newValue, editingDisplayName != v {
                    editingDisplayName = v
                }
            }
            .onChange(of: showCopiedFeedback) { _, newValue in
                if newValue {
                    _Concurrency.Task { @MainActor in
                        try? await _Concurrency.Task.sleep(nanoseconds: 1_500_000_000)
                        showCopiedFeedback = false
                    }
                }
            }
            .sheet(isPresented: $showApprovalPending) {
                ApprovalPendingView()
                    .environmentObject(taskViewModel)
            }
        }
    }
    
    private var canSaveProfile: Bool {
        let name = editingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty && authManager.currentUser != nil
    }
    
    private func saveProfile() async {
        guard canSaveProfile else { return }
        isSavingProfile = true
        profileSaveMessage = nil
        defer { isSavingProfile = false }
        do {
            try await authManager.updateProfile(
                displayName: editingDisplayName.trimmingCharacters(in: .whitespacesAndNewlines),
                avatarEmoji: authManager.userProfile?.avatarEmoji ?? "👤"
            )
            profileSaveMessage = "保存しました"
            HapticManager.shared.mediumImpact()
        } catch {
            profileSaveMessage = "保存に失敗: \(error.localizedDescription)"
        }
    }
    
    private func copyUIDToPasteboard() {
        guard let uid = authManager.currentUser?.uid else { return }
        UIPasteboard.general.string = uid
        HapticManager.shared.mediumImpact()
        showCopiedFeedback = true
    }
}

#Preview {
    SettingsView()
        .environmentObject(TaskViewModel())
}
