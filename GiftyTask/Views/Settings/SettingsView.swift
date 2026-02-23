import SwiftUI

// MARK: - 設定画面（自分のUID表示・コピー）
struct SettingsView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showCopiedFeedback = false
    
    private var currentUID: String {
        authManager.currentUser?.uid ?? "未ログイン"
    }
    
    var body: some View {
        NavigationView {
            Form {
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
                        Text("タップでコピー")
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
