import SwiftUI
import FirebaseCore

// MARK: - GiftyTask App Entry Point
@main
struct GiftyTaskApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
