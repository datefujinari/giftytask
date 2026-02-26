import SwiftUI

// MARK: - Content View (メインタブビュー)
struct ContentView: View {
    @ObservedObject private var authManager = AuthManager.shared
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var giftViewModel = GiftViewModel()
    @StateObject private var epicViewModel = EpicViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(taskViewModel)
                .environmentObject(activityViewModel)
                .environmentObject(giftViewModel)
                .environmentObject(epicViewModel)
                .tabItem {
                    Label("ダッシュボード", systemImage: "house.fill")
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
                .tabItem {
                    Label("受信BOX", systemImage: "tray.and.arrow.down.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .task {
            // 実機テスト用: 未ログインなら匿名ログインを実行
            guard authManager.currentUser == nil, !authManager.isLoading else { return }
            do {
                try await authManager.signInAnonymously()
            } catch {
                print("❌ 匿名ログイン失敗: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
