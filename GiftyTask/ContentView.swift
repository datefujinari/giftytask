import SwiftUI

// MARK: - Content View (メインタブビュー)
struct ContentView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var giftViewModel = GiftViewModel()
    @StateObject private var epicViewModel = EpicViewModel()
    @StateObject private var routineViewModel = RoutineViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RoutineListView()
                .environmentObject(routineViewModel)
                .environmentObject(giftViewModel)
                .tabItem {
                    Label("ルーティン", systemImage: "repeat.circle")
                }
                .tag(0)
            
            TaskListView()
                .environmentObject(taskViewModel)
                .environmentObject(activityViewModel)
                .environmentObject(giftViewModel)
                .environmentObject(epicViewModel)
                .tabItem {
                    Label("タスク", systemImage: "checklist")
                }
                .tag(1)
            
            GiftListView()
                .environmentObject(giftViewModel)
                .environmentObject(taskViewModel)
                .environmentObject(activityViewModel)
                .environmentObject(epicViewModel)
                .tabItem {
                    Label("ギフトBOX", systemImage: "gift.fill")
                }
                .tag(2)
            
            ReceivedBoxView()
                .environmentObject(taskViewModel)
                .environmentObject(giftViewModel)
                .environmentObject(routineViewModel)
                .tabItem {
                    Label("受信BOX", systemImage: "tray.and.arrow.down.fill")
                }
                .tag(3)
            
            SettingsView()
                .environmentObject(taskViewModel)
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            taskViewModel.giftViewModel = giftViewModel
            taskViewModel.activityViewModel = activityViewModel
            routineViewModel.giftViewModel = giftViewModel
        }
        .task {
            guard authManager.currentUser == nil, !authManager.isLoading else { return }
            do {
                try await authManager.signInAnonymously()
            } catch {
                print("❌ 匿名ログイン失敗: \(error.localizedDescription)")
            }
        }
        // 認証後すぐ Firestore 購読を開始（受信BOXを開かないと届かなかったルーティン提案通知のため）
        .task(id: authManager.currentUser?.uid) {
            guard let uid = authManager.currentUser?.uid, !uid.isEmpty else {
                taskViewModel.stopListeningReceivedTasks()
                taskViewModel.stopListeningSentTasks()
                routineViewModel.stopListeningRoutineSuggestions()
                return
            }
            taskViewModel.giftViewModel = giftViewModel
            taskViewModel.activityViewModel = activityViewModel
            routineViewModel.giftViewModel = giftViewModel
            await taskViewModel.loadTasks()
            routineViewModel.startListeningRoutineSuggestions()
        }
        // タブ切替で消えないようルートに集約。下スワイプでは閉じず「閉じる」のみ。
        .sheet(item: Binding(
            get: { giftViewModel.lastUnlockedGift },
            set: { giftViewModel.lastUnlockedGift = $0 }
        )) { gift in
            CelebrationModal(
                message: "おめでとう🎉",
                subtitle: gift.title,
                detail: ContentView.giftUnlockCelebrationDetail(for: gift)
            )
            .interactiveDismissDisabled(true)
            .presentationDragIndicator(.hidden)
        }
    }
    
    /// フレンド割当ギフトは「承認」文面、それ以外は一般的な案内
    private static func giftUnlockCelebrationDetail(for gift: Gift) -> String {
        if gift.type == .friendAssigned {
            return "相手がタスクを承認し、ギフトが解禁されました。\nギフトBOXの「アンロック済み」からご利用ください。"
        }
        return "ギフトが解禁されました。\nギフトBOXの「アンロック済み」からご利用ください。"
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
