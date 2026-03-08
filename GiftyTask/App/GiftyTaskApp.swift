import SwiftUI
import FirebaseCore

// MARK: - GiftyTask App Entry Point
@main
struct GiftyTaskApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
