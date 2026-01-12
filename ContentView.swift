import SwiftUI

// MARK: - Content View (メインタブビュー)
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ダッシュボード
            DashboardView()
                .tabItem {
                    Label("ダッシュボード", systemImage: "house.fill")
                }
                .tag(0)
            
            // タスク一覧
            TaskListView()
                .tabItem {
                    Label("タスク", systemImage: "checklist")
                }
                .tag(1)
            
            // ギフトBOX
            GiftListView()
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

