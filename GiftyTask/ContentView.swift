import SwiftUI

// MARK: - Content View (メインタブビュー)
struct ContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ダッシュボード
            DashboardView()
                .environmentObject(taskViewModel)
                .environmentObject(activityViewModel)
                .tabItem {
                    Label("ダッシュボード", systemImage: "house.fill")
                }
                .tag(0)
            
            // タスク一覧
            TaskListView()
                .environmentObject(taskViewModel)
                .environmentObject(activityViewModel)
                .tabItem {
                    Label("タスク", systemImage: "checklist")
                }
                .tag(1)
            
            // ギフトBOX
            GiftListView()
                .environmentObject(taskViewModel)
                .environmentObject(activityViewModel)
                .tabItem {
                    Label("ギフトBOX", systemImage: "gift.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
