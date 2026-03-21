import SwiftUI

// MARK: - Routine Detail View
struct RoutineDetailView: View {
    let routine: Routine
    @EnvironmentObject var routineViewModel: RoutineViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    
    @State private var calendarDays: [CalendarDay] = []
    @State private var streak = 0
    @State private var showEditSheet = false
    @State private var showCelebration = false
    @State private var showUnlockAlert = false
    @State private var unlockAlertGiftTitle = ""
    
    private var currentRoutine: Routine {
        routineViewModel.routines.first(where: { $0.id == routine.id }) ?? routine
    }
    
    private var linkedGiftTitle: String {
        guard !currentRoutine.associatedGiftId.isEmpty,
              let g = giftViewModel.gifts.first(where: { $0.id == currentRoutine.associatedGiftId }) else {
            return "ギフト未設定"
        }
        return g.title
    }
    
    private let primaryColor = Color(hex: "#4F46E5")
    private let secondaryColor = Color(hex: "#6B7280")
    
    private var target: Int { max(1, currentRoutine.targetCount) }
    private var cycleProgress: Double {
        min(1.0, Double(currentRoutine.currentCycleCount) / Double(target))
    }
    
    var body: some View {
        detailStack
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
            .onAppear(perform: refreshData)
            .onChange(of: currentRoutine.completionHistory.count) { _, _ in refreshData() }
            .onChange(of: currentRoutine.currentCycleCount) { _, _ in refreshData() }
            .onChange(of: currentRoutine.targetCount) { _, _ in refreshData() }
            .onChange(of: routineViewModel.routineGiftUnlockEvent) { _, new in
                handleUnlockEvent(new)
            }
            .sheet(isPresented: $showEditSheet) {
                EditRoutineSheet(isPresented: $showEditSheet, routine: currentRoutine)
                    .environmentObject(routineViewModel)
                    .environmentObject(giftViewModel)
            }
            .alert("おめでとう！🎉", isPresented: $showUnlockAlert) {
                Button("OK") {
                    routineViewModel.clearRoutineGiftUnlockEvent()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showCelebration = false
                    }
                }
            } message: {
                Text("ギフト「\(unlockAlertGiftTitle)」を獲得しました。\nギフトBOXの「アンロック済み」で確認できます。")
            }
    }
    
    private var detailStack: some View {
        ZStack {
            scrollContent
            RoutineConfettiOverlay(isActive: showCelebration)
        }
    }
    
    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statsCard
                giftProgressSection
                RoutineDetailCalendarSection(
                    calendarDays: calendarDays,
                    routine: currentRoutine,
                    viewModel: routineViewModel,
                    secondaryColor: secondaryColor
                )
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
    }
    
    private func handleUnlockEvent(_ new: RoutineGiftUnlockEvent?) {
        guard let e = new, e.routineId == routine.id else { return }
        unlockAlertGiftTitle = e.giftTitle
        showCelebration = true
        showUnlockAlert = true
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
        ZStack {
            Circle()
                .stroke(secondaryColor.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)
            Circle()
                .trim(from: 0, to: cycleProgress)
                .stroke(primaryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
            Text("\(currentRoutine.currentCycleCount)/\(target)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(primaryColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(width: 72)
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
    
    private var giftProgressSection: some View {
        RoutineDetailGiftProgressCard(
            linkedGiftTitle: linkedGiftTitle,
            currentCount: currentRoutine.currentCycleCount,
            target: target,
            cycleProgress: cycleProgress,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor
        )
    }
    
    private func refreshData() {
        calendarDays = routineViewModel.generateCalendarData(for: currentRoutine, referenceMonth: Date())
        streak = routineViewModel.calculateStreak(for: currentRoutine)
    }
}

// MARK: - ギフト進捗（型推論負荷を分離）
private struct RoutineDetailGiftProgressCard: View {
    let linkedGiftTitle: String
    let currentCount: Int
    let target: Int
    let cycleProgress: Double
    let primaryColor: Color
    let secondaryColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎁 ご褒美")
                    .font(.headline)
                Spacer()
                Text(linkedGiftTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(primaryColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            Text("次のギフトまで \(currentCount) / \(target) 日")
                .font(.subheadline)
                .foregroundColor(secondaryColor)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(secondaryColor.opacity(0.15))
                        .frame(height: 10)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [primaryColor, primaryColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * cycleProgress), height: 10)
                }
            }
            .frame(height: 10)
        }
        .padding(20)
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - カレンダー（月グリッド・LazyVGrid）
private struct RoutineDetailCalendarSection: View {
    let calendarDays: [CalendarDay]
    let routine: Routine
    @ObservedObject var viewModel: RoutineViewModel
    let secondaryColor: Color
    
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 32), spacing: 6, alignment: .center), count: 7)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カレンダー")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                weekdayHeaderRow
                
                LazyVGrid(columns: gridColumns, alignment: .center, spacing: 10) {
                    ForEach(Array(calendarDays.enumerated()), id: \.element.id) { index, day in
                        CalendarDayWithFlipView(
                            day: day,
                            routine: routine,
                            viewModel: viewModel,
                            delayIndex: index
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.8))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    private var weekdayHeaderRow: some View {
        LazyVGrid(columns: gridColumns, alignment: .center, spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, w in
                Text(w)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(weekdayHeaderColor(index: index))
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func weekdayHeaderColor(index: Int) -> Color {
        if index == 0 { return Color.red.opacity(0.85) }
        if index == 6 { return Color.blue.opacity(0.8) }
        return secondaryColor
    }
}
