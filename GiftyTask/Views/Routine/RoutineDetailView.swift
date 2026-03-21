import SwiftUI

// MARK: - Routine Detail View
struct RoutineDetailView: View {
    let routine: Routine
    @EnvironmentObject var routineViewModel: RoutineViewModel
    
    @State private var calendarData: [[CalendarDay]] = []
    @State private var streak = 0
    @State private var isLoaded = false
    @State private var showEditSheet = false
    
    private var currentRoutine: Routine {
        routineViewModel.routines.first(where: { $0.id == routine.id }) ?? routine
    }
    
    private let primaryColor = Color(hex: "#4F46E5")
    private let secondaryColor = Color(hex: "#6B7280")
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statsCard
                calendarSection
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color.white, Color(hex: "#F0F4FF")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle(currentRoutine.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("編集") {
                    showEditSheet = true
                }
                .foregroundColor(primaryColor)
            }
        }
        .onAppear {
            refreshData()
        }
        .onChange(of: currentRoutine.completionHistory.count) { _, _ in
            refreshData()
        }
        .sheet(isPresented: $showEditSheet) {
            EditRoutineSheet(isPresented: $showEditSheet, routine: currentRoutine)
                .environmentObject(routineViewModel)
        }
    }
    
    private var statsCard: some View {
        HStack(spacing: 24) {
            progressCircle
            streakView
            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var progressCircle: some View {
        let totalDays = 7 * 4
        let completedCount = currentRoutine.completionHistory.filter { dateString in
            guard let date = isoDate(from: dateString) else { return false }
            let calendar = Calendar.current
            let now = Date()
            let fourWeeksAgo = calendar.date(byAdding: .day, value: -totalDays, to: now) ?? now
            return date >= fourWeeksAgo && date <= now
        }.count
        let progress = min(1.0, Double(completedCount) / Double(totalDays))
        
        return ZStack {
            Circle()
                .stroke(secondaryColor.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(primaryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(primaryColor)
        }
    }
    
    private var streakView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                Text("\(streak)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
            }
            Text("連続達成")
                .font(.system(size: 14))
                .foregroundColor(secondaryColor)
        }
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カレンダー")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                weekdayHeader
                ForEach(Array(calendarData.enumerated()), id: \.offset) { weekIndex, week in
                    HStack(spacing: 8) {
                        ForEach(Array(week.enumerated()), id: \.element.id) { dayIndex, day in
                            CalendarDayWithFlipView(
                                day: day,
                                routine: currentRoutine,
                                viewModel: routineViewModel,
                                delayIndex: weekIndex * 7 + dayIndex
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.8))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    private var weekdayHeader: some View {
        let weekdays = ["月", "火", "水", "木", "金", "土", "日"]
        return HStack(spacing: 8) {
            ForEach(weekdays, id: \.self) { w in
                Text(w)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryColor)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func refreshData() {
        calendarData = routineViewModel.generateCalendarData(for: currentRoutine, weeksToShow: 4)
        streak = routineViewModel.calculateStreak(for: currentRoutine)
        isLoaded = true
    }
    
    private func isoDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: string)
    }
}
