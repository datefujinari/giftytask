import SwiftUI

// MARK: - タスク送信画面（他ユーザーへタスク＋ギフトを送る）
struct SendTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var taskRepo = TaskRepository.shared
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var taskTitle = ""
    @State private var giftName = ""
    @State private var receiverId = ""
    @State private var targetDays: Int = 1
    @State private var addToFriendList = true
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    @State private var friendDisplayNames: [String: String] = [:]
    
    private var friendList: [String] {
        authManager.userProfile?.friendList ?? []
    }
    
    var body: some View {
        NavigationView {
            Form {
                // フレンドから選ぶ
                if !friendList.isEmpty {
                    Section("フレンドから選ぶ") {
                        ForEach(friendList, id: \.self) { uid in
                            Button {
                                receiverId = uid
                                HapticManager.shared.selectionChanged()
                            } label: {
                                HStack {
                                    Text(friendDisplayNames[uid] ?? uid)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    if receiverId == uid {
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
                Section("タスク") {
                    TextField("タスク名", text: $taskTitle)
                        .textContentType(.none)
                        .autocapitalization(.sentences)
                    Picker("目標日数", selection: $targetDays) {
                        ForEach(1...30, id: \.self) { n in
                            Text("\(n)日").tag(n)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("ギフト") {
                    TextField("ギフト名", text: $giftName)
                        .textContentType(.none)
                        .autocapitalization(.sentences)
                }
                Section("送信先") {
                    TextField("相手のユーザーID（UID）", text: $receiverId)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    Toggle("フレンドに追加する", isOn: $addToFriendList)
                        .disabled(receiverId.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                Section {
                    Button {
                        _Concurrency.Task { @MainActor in
                            await sendTask()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("送信する")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .background(canSend ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canSend || isSending)
                }
            }
            .navigationTitle("タスクを送る")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .alert("送信しました", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("タスクを送信しました。相手が承諾するとタスクが開始されます。")
            }
            .task(id: friendList.map { $0 }.joined(separator: ",")) {
                await loadFriendDisplayNames()
            }
        }
    }
    
    private func loadFriendDisplayNames() async {
        var names: [String: String] = [:]
        for uid in friendList {
            if let profile = await AuthManager.shared.fetchOtherUserProfile(uid: uid) {
                names[uid] = profile.displayName
            }
        }
        friendDisplayNames = names
    }
    
    private var canSend: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !giftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !receiverId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendTask() async {
        errorMessage = nil
        isSending = true
        let receiver = receiverId.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await taskRepo.sendTask(
                title: taskTitle,
                giftName: giftName,
                receiverId: receiver,
                targetDays: targetDays
            )
            if addToFriendList, !receiver.isEmpty {
                try? await authManager.addFriend(receiver)
            }
            isSending = false
            showSuccess = true
        } catch {
            isSending = false
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SendTaskView()
}
