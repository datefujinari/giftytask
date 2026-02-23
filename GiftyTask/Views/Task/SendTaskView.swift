import SwiftUI

// MARK: - タスク送信画面（他ユーザーへタスク＋ギフトを送る）
struct SendTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var taskRepo = TaskRepository.shared
    
    @State private var taskTitle = ""
    @State private var giftName = ""
    @State private var receiverId = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("タスク") {
                    TextField("タスク名", text: $taskTitle)
                        .textContentType(.none)
                        .autocapitalization(.sentences)
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
                        sendTask()
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
        }
    }
    
    private var canSend: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !giftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !receiverId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendTask() {
        errorMessage = nil
        isSending = true
        Task {
            do {
                _ = try await taskRepo.sendTask(
                    title: taskTitle,
                    giftName: giftName,
                    receiverId: receiverId.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                await MainActor.run {
                    isSending = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    SendTaskView()
}
