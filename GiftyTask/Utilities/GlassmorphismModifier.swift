import SwiftUI

// MARK: - Glassmorphism Modifier
struct GlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.2
    var blur: CGFloat = 10
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

extension View {
    func glassmorphism(
        cornerRadius: CGFloat = 20,
        opacity: Double = 0.2,
        blur: CGFloat = 10
    ) -> some View {
        modifier(GlassmorphismModifier(
            cornerRadius: cornerRadius,
            opacity: opacity,
            blur: blur
        ))
    }
}

// MARK: - Locked Glassmorphism (半透明ロック効果)
struct LockedGlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var isLocked: Bool = true
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.black.opacity(isLocked ? 0.3 : 0))
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isLocked ? 0.3 : 0.6),
                                                Color.white.opacity(isLocked ? 0.1 : 0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .overlay(
                Group {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.6))
                            .blur(radius: 0.5)
                    }
                }
            )
    }
}

extension View {
    func lockedGlassmorphism(
        cornerRadius: CGFloat = 20,
        isLocked: Bool = true
    ) -> some View {
        modifier(LockedGlassmorphismModifier(
            cornerRadius: cornerRadius,
            isLocked: isLocked
        ))
    }
}

