import SwiftUI

// MARK: - 目標達成時の簡易お祝い演出（絵文字＋スケール）
struct RoutineConfettiOverlay: View {
    let isActive: Bool
    
    @State private var scale: CGFloat = 0.01
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Text("🎉")
                .font(.system(size: 80))
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            guard active else {
                scale = 0.01
                opacity = 0
                return
            }
            scale = 0.2
            opacity = 1
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                scale = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.35)) {
                    opacity = 0
                    scale = 0.5
                }
            }
        }
    }
}
