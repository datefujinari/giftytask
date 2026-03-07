import SwiftUI

// MARK: - 使用可能な絵文字一覧
private let avatarEmojiOptions = ["👤", "😊", "🔥", "⭐️", "🎯", "💪", "✨", "🌟", "🎉", "❤️", "🌈", "🚀"]

// MARK: - 設定画面（プロフィール編集・UID表示・コピー・累計達成数）
struct SettingsView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showCopiedFeedback = false
    @State private var editingDisplayName = ""
    @State private var editingAvatarEmoji = "👤"
    @State private var isSavingProfile = false
    @State private var profileSaveMessage: String?
    
    private var currentUID: String {
        authManager.currentUser?.uid ?? "未ログイン"
    }
    
    var body: some View {
        NavigationView {
            Form {
                // プロフィール編集
                Section {
                    HStack(spacing: 16) {
                        Text(editingAvatarEmoji)
                            .font(.system(size: 48))
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("ニックネーム", text: $editingDisplayName)
                                .textContentType(.nickname)
                                .autocapitalization(.words)
                            Text("絵文字をタップして変更")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(avatarEmojiOptions, id: \.self) { emoji in
                            Button {
                                editingAvatarEmoji = emoji
                                HapticManager.shared.lightImpact()
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(editingAvatarEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
                editingAvatarEmoji = authManager.userProfile?.avatarEmoji ?? "👤"
            }
            .onChange(of: authManager.userProfile?.displayName) { _, newValue in
                if let v = newValue, editingDisplayName != v {
                    editingDisplayName = v
                }
            }
            .onChange(of: authManager.userProfile?.avatarEmoji) { _, newValue in
                if let v = newValue, editingAvatarEmoji != v {
                    editingAvatarEmoji = v
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
                avatarEmoji: editingAvatarEmoji
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
}
