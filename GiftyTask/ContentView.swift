import SwiftUI

// MARK: - Content View (メインタブビュー)
struct ContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()
    @StateObject private var giftViewModel = GiftViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .environmentObject(taskViewModel)
                .environmentObject(activityViewModel)
                .environmentObject(giftViewModel)
                .tabItem {
                    Label("ダッシュボード", systemImage: "house.fill")
                }
                .tag(0)
            
            TaskListView()
                .environmentObject(taskViewModel)
                .environmentObject(activityViewModel)
                .environmentObject(giftViewModel)
                .tabItem {
                    Label("タスク", systemImage: "checklist")
                }
                .tag(1)
            
            GiftListView()
                .environmentObject(giftViewModel)
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
