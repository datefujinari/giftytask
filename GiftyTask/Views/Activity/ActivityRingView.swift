import SwiftUI

// MARK: - Activity Ring View (Apple Health Style)
struct ActivityRingView: View {
    var ringData: ActivityRingData
    var size: CGFloat = 100
    var lineWidth: CGFloat = 12
    
    var body: some View {
        ZStack {
            // Move Ring (完了タスク数)
            Circle()
                .stroke(
                    Color.red.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: ringData.move)
                .stroke(
                    LinearGradient(
                        colors: [Color.red, Color.pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: ringData.move)
            
            // Exercise Ring (エピック進捗)
            Circle()
                .stroke(
                    Color.green.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size - lineWidth * 2.2, height: size - lineWidth * 2.2)
            
            Circle()
                .trim(from: 0, to: ringData.exercise)
                .stroke(
                    LinearGradient(
                        colors: [Color.green, Color.mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size - lineWidth * 2.2, height: size - lineWidth * 2.2)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: ringData.exercise)
            
            // Stand Ring (アクティブ日数)
            Circle()
                .stroke(
                    Color.blue.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size - lineWidth * 4.4, height: size - lineWidth * 4.4)
            
            Circle()
                .trim(from: 0, to: ringData.stand)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size - lineWidth * 4.4, height: size - lineWidth * 4.4)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: ringData.stand)
        }
    }
}

// MARK: - Activity Ring Card View (表示用カード)
struct ActivityRingCardView: View {
    var ringData: ActivityRingData
    var completedTasks: Int
    var goalTasks: Int
    var epicProgress: Double
    var activeDays: Int
    var totalDays: Int
    
    var body: some View {
        VStack(spacing: 20) {
            ActivityRingView(
                ringData: ringData,
                size: 150,
                lineWidth: 15
            )
            
            VStack(spacing: 12) {
                // Move Ring Info
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.red, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 12, height: 12)
                    
                    Text("完了タスク")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(completedTasks)/\(goalTasks)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                // Exercise Ring Info
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.green, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 12, height: 12)
                    
                    Text("エピック進捗")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(epicProgress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                // Stand Ring Info
                HStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 12, height: 12)
                    
                    Text("アクティブ日")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(activeDays)/\(totalDays)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(24)
        .glassmorphism(cornerRadius: 24)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 40) {
        ActivityRingCardView(
            ringData: PreviewContainer.mockActivityRingData,
            completedTasks: PreviewContainer.mockActivityData.completedTasksCount,
            goalTasks: PreviewContainer.mockActivityData.totalTasksCount,
            epicProgress: 0.6,
            activeDays: 17,
            totalDays: 20
        )
        .padding()
    }
    .padding()
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

