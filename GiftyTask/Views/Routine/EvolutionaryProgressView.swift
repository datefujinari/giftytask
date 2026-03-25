import SwiftUI

// MARK: - HTML デモ準拠: 進化時ポップイン + 100% で squash-stretch ループ + カード反転

private struct BounceKeyframeSample {
    var sx: CGFloat
    var sy: CGFloat
    var offsetY: CGFloat
    var shadowScaleX: CGFloat
    var shadowOpacity: Double
}

// MARK: - Evolutionary Progress View（進捗アイコン + タップで数値表示）
struct EvolutionaryProgressView: View {
    let progress: Double
    let displayText: String
    
    @State private var isFlipped = false
    @State private var displayedImageName: String
    @State private var switchEntryScale: CGFloat = 1
    @State private var switchEntryOpacity: Double = 1
    
    init(progress: Double, displayText: String) {
        self.progress = progress
        self.displayText = displayText
        _displayedImageName = State(initialValue: Self.imageName(for: progress))
    }
    
    private let primaryColor = Color(hex: "#4F46E5")
    
    private var isComplete: Bool {
        progress >= 1.0
    }
    
    private var gaugeColor: Color {
        if progress >= 1.0 { return primaryColor }
        if progress >= 0.3 { return Color.green }
        return Color.orange
    }
    
    private var progressImageName: String {
        Self.imageName(for: progress)
    }
    
    private static func imageName(for progress: Double) -> String {
        switch progress {
        case 0: return "sad 1"
        case 0.01..<0.5: return "normal 1"
        case 0.5..<1.0: return "smile 1"
        default: return "happy 1"
        }
    }
    
    private let ringSize: CGFloat = 120
    private let iconSize: CGFloat = 60
    private let lineWidth: CGFloat = 8
    private let shadowEllipseWidth: CGFloat = 40
    private let shadowEllipseHeight: CGFloat = 6
    private let switchAnimationPhaseDuration: TimeInterval = 0.15
    /// @keyframes squash-stretch / shadow-scale の周期
    private let bounceCycleDuration: TimeInterval = 0.8
    
    /// CSS: 0%,100% → 40% → 60% → 100%（線形補間）
    private func bounceSample(phase: CGFloat) -> BounceKeyframeSample {
        let a = BounceKeyframeSample(sx: 1.15, sy: 0.85, offsetY: 0, shadowScaleX: 1.2, shadowOpacity: 0.3)
        let b = BounceKeyframeSample(sx: 0.85, sy: 1.2, offsetY: -15, shadowScaleX: 0.5, shadowOpacity: 0.1)
        let c = BounceKeyframeSample(sx: 0.95, sy: 1.05, offsetY: -20, shadowScaleX: 0.5, shadowOpacity: 0.1)
        
        if phase < 0.4 {
            let u = phase / 0.4
            return lerp(a, b, u)
        } else if phase < 0.6 {
            let u = (phase - 0.4) / 0.2
            return lerp(b, c, u)
        } else {
            let u = (phase - 0.6) / 0.4
            return lerp(c, a, u)
        }
    }
    
    private func lerp(_ x: BounceKeyframeSample, _ y: BounceKeyframeSample, _ u: CGFloat) -> BounceKeyframeSample {
        BounceKeyframeSample(
            sx: x.sx + (y.sx - x.sx) * u,
            sy: x.sy + (y.sy - x.sy) * u,
            offsetY: x.offsetY + (y.offsetY - x.offsetY) * u,
            shadowScaleX: x.shadowScaleX + (y.shadowScaleX - x.shadowScaleX) * u,
            shadowOpacity: x.shadowOpacity + (y.shadowOpacity - x.shadowOpacity) * Double(u)
        )
    }
    
    var body: some View {
        Button {
            HapticManager.shared.selectionChanged()
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.6)) {
                isFlipped.toggle()
            }
        } label: {
            ZStack {
                backView
                frontView
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
            }
        }
        .buttonStyle(.plain)
        .task(id: progressImageName) {
            let new = progressImageName
            guard new != displayedImageName else { return }
            displayedImageName = new
            var snap = Transaction()
            snap.disablesAnimations = true
            withTransaction(snap) {
                switchEntryScale = 0.5
                switchEntryOpacity = 0
            }
            withAnimation(.easeOut(duration: switchAnimationPhaseDuration)) {
                switchEntryScale = 1.2
                switchEntryOpacity = 1
            }
            do {
                // アプリの `Task` モデルと区別するため _Concurrency.Task を明示
                try await _Concurrency.Task.sleep(nanoseconds: UInt64(switchAnimationPhaseDuration * 1_000_000_000))
                withAnimation(.easeOut(duration: switchAnimationPhaseDuration)) {
                    switchEntryScale = 1
                }
            } catch is CancellationError {
            } catch {}
        }
    }
    
    private var frontView: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: lineWidth)
                .frame(width: ringSize, height: ringSize)
            Circle()
                .trim(from: 0, to: min(1.0, max(0, progress)))
                .stroke(
                    gaugeColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
                .animation(.easeInOut(duration: 0.3), value: gaugeColor)
            
            characterWithShadow
                .frame(width: ringSize, height: ringSize)
                .clipShape(Circle())
        }
        .opacity(isFlipped ? 0 : 1)
    }
    
    private var characterWithShadow: some View {
        Group {
            if isComplete {
                TimelineView(.animation(minimumInterval: 1 / 60)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: bounceCycleDuration) / bounceCycleDuration
                    let s = bounceSample(phase: CGFloat(t))
                    characterCore(bounce: s)
                }
            } else {
                characterCore(bounce: nil)
            }
        }
    }
    
    private func characterCore(bounce: BounceKeyframeSample?) -> some View {
        let bx = bounce?.sx ?? 1
        let by = bounce?.sy ?? 1
        let oy = bounce?.offsetY ?? 0
        let shx = bounce?.shadowScaleX ?? 1
        let shop = bounce?.shadowOpacity ?? 0
        
        return VStack(spacing: 2) {
            Image(displayedImageName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .clipShape(Circle())
                .scaleEffect(switchEntryScale)
                .opacity(switchEntryOpacity)
                .scaleEffect(x: bx, y: by, anchor: .bottom)
                .offset(y: oy)
            
            Ellipse()
                .fill(Color.black.opacity(0.25))
                .frame(width: shadowEllipseWidth, height: shadowEllipseHeight)
                .scaleEffect(x: shx, y: 1, anchor: .center)
                .opacity(shop)
        }
    }
    
    private var backView: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.2), lineWidth: lineWidth)
                .frame(width: ringSize, height: ringSize)
            Circle()
                .trim(from: 0, to: min(1.0, max(0, progress)))
                .stroke(
                    gaugeColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: ringSize, height: ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
                .animation(.easeInOut(duration: 0.3), value: gaugeColor)
            
            Text(displayText)
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: ringSize - 24)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 0 : -180),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .opacity(isFlipped ? 1 : 0)
    }
}

#Preview {
    VStack(spacing: 32) {
        EvolutionaryProgressView(progress: 0, displayText: "0/7")
        EvolutionaryProgressView(progress: 0.3, displayText: "2/7")
        EvolutionaryProgressView(progress: 0.7, displayText: "5/7")
        EvolutionaryProgressView(progress: 1.0, displayText: "7/7")
    }
    .padding()
}
