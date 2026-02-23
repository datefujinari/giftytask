import SwiftUI
import FirebaseCore

// MARK: - GiftyTask App Entry Point
@main
struct GiftyTaskApp: App {
    init() {
        FirebaseApp.configure()
        // 匿名ログインは ContentView 表示時の .task で実行（未ログイン時のみ）
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
