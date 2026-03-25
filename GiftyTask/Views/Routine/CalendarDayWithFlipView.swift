import SwiftUI

// MARK: - フリップアニメーション付きカレンダー日付
struct CalendarDayWithFlipView: View {
    let day: CalendarDay
    let routine: Routine
    @ObservedObject var viewModel: RoutineViewModel
    let delayIndex: Int
    
    @State private var isFlipped = false
    
    private let primaryColor = Color(hex: "#4F46E5")
    
    private var weekday: Int {
        Calendar.current.component(.weekday, from: day.date)
    }
    
    private var isSunday: Bool { weekday == 1 }
    private var isSaturday: Bool { weekday == 7 }
    
    /// 日付数字の色（完了時は白は親側で上書き）
    private var dayNumberColor: Color {
        if day.isCompleted { return .white }
        if !day.isInDisplayedMonth { return Color.secondary.opacity(0.45) }
        if isSunday { return Color.red.opacity(0.88) }
        if isSaturday { return Color.blue.opacity(0.78) }
        return Color.secondary
    }
    
    private var incompleteCircleFill: Color {
        if !day.isInDisplayedMonth { return Color.secondary.opacity(0.12) }
        return Color.secondary.opacity(0.28)
    }
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.6).delay(Double(delayIndex) * 0.02)) {
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
            withAnimation(.easeInOut(duration: 0.6).delay(Double(delayIndex) * 0.02)) {
                isFlipped = newValue
            }
        }
    }
    
    private var frontView: some View {
        ZStack {
            Circle()
                .fill(day.isCompleted ? Color.black : incompleteCircleFill)
                .frame(width: 36, height: 36)
            if day.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                Text(dayLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(dayNumberColor)
            }
            if day.isToday {
                Circle()
                    .stroke(primaryColor, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
        }
        .opacity(isFlipped ? 0 : 1)
    }
    
    private var backView: some View {
        ZStack {
            Circle()
                .fill(day.isCompleted ? Color.black : incompleteCircleFill)
                .frame(width: 36, height: 36)
            if day.isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            } else {
                Text(dayLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(dayNumberColor)
            }
            if day.isToday {
                Circle()
                    .stroke(primaryColor, lineWidth: 2)
                    .frame(width: 40, height: 40)
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
        formatter.timeZone = TimeZone.current
        return formatter.string(from: day.date)
    }
}
