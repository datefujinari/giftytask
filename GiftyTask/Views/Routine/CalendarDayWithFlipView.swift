import SwiftUI

// MARK: - フリップアニメーション付きカレンダー日付
struct CalendarDayWithFlipView: View {
    let day: CalendarDay
    let routine: Routine
    @ObservedObject var viewModel: RoutineViewModel
    let delayIndex: Int
    
    @State private var isFlipped = false
    
    private let primaryColor = Color(hex: "#4F46E5")
    private let secondaryColor = Color(hex: "#6B7280")
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.6).delay(Double(delayIndex) * 0.05)) {
                isFlipped.toggle()
            }
            viewModel.toggleRoutineCompletion(id: routine.id, date: day.dateString)
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
        .onAppear {
            isFlipped = day.isCompleted
        }
        .onChange(of: day.isCompleted) { _, newValue in
            withAnimation(.easeInOut(duration: 0.6).delay(Double(delayIndex) * 0.05)) {
                isFlipped = newValue
            }
        }
    }
    
    private var frontView: some View {
        ZStack {
            Circle()
                .fill(day.isCompleted ? Color.black : secondaryColor.opacity(0.3))
                .frame(width: 36, height: 36)
            if day.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                Text(dayLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryColor)
            }
        }
        .opacity(isFlipped ? 0 : 1)
    }
    
    private var backView: some View {
        ZStack {
            Circle()
                .fill(day.isCompleted ? Color.black : secondaryColor.opacity(0.3))
                .frame(width: 36, height: 36)
            if day.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                Text(dayLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryColor)
            }
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 0 : -180),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        .opacity(isFlipped ? 1 : 0)
    }
    
    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: day.date)
    }
}
