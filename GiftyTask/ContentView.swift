import SwiftUI

// MARK: - Content View (メインタブビュー)
struct ContentView: View {
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
        }
        .accentColor(.blue)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
