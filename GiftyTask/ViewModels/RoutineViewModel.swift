import Foundation
import Combine

// MARK: - CalendarDay（カレンダー表示用）
struct CalendarDay: Identifiable {
    let id: String
    let dateString: String
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
}

// MARK: - Routine ViewModel
@MainActor
class RoutineViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    
    private static let routinesKey = "routines_data"
    
    init() {
        loadRoutines()
    }
    
    func addRoutine(_ routine: Routine) {
        var r = routine
        r.order = routines.count
        routines.append(r)
        saveRoutines()
    }
    
    func updateRoutine(_ routine: Routine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        routines[index] = routine
        saveRoutines()
    }
    
    func deleteRoutine(id: UUID) {
        routines.removeAll { $0.id == id }
        saveRoutines()
    }
    
    func toggleRoutineCompletion(id: UUID, date: String) {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return }
        var routine = routines[index]
        if routine.completionHistory.contains(date) {
            routine.completionHistory.removeAll { $0 == date }
        } else {
            routine.completionHistory.append(date)
            routine.completionHistory.sort()
        }
        routines[index] = routine
        saveRoutines()
    }
    
    /// カレンダー表示用のデータを生成（4週間分）
    func generateCalendarData(for routine: Routine, weeksToShow: Int = 4) -> [[CalendarDay]] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayString = formatter.string(from: today)
        
        // 週の開始を月曜とする
        var startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekday = calendar.component(.weekday, from: startDate)
        if weekday == 1 {
            startDate = calendar.date(byAdding: .day, value: -6, to: startDate)!
        } else if weekday > 2 {
            startDate = calendar.date(byAdding: .day, value: -(weekday - 2), to: startDate)!
        }
        
        var result: [[CalendarDay]] = []
        for week in 0..<weeksToShow {
            var weekDays: [CalendarDay] = []
            for dayOffset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: week * 7 + dayOffset, to: startDate) else { continue }
                let dateString = formatter.string(from: date)
                let isCompleted = routine.completionHistory.contains(dateString)
                let isToday = calendar.isDate(date, inSameDayAs: today)
                weekDays.append(CalendarDay(
                    id: dateString,
                    dateString: dateString,
                    date: date,
                    isCompleted: isCompleted,
                    isToday: isToday
                ))
            }
            result.append(weekDays)
        }
        return result
    }
    
    /// 連続達成日数を計算
    func calculateStreak(for routine: Routine) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayString = formatter.string(from: today)
        
        guard routine.completionHistory.contains(todayString) else { return 0 }
        
        var streak = 0
        var checkDate = today
        while true {
            let checkString = formatter.string(from: checkDate)
            if routine.completionHistory.contains(checkString) {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            } else {
                break
            }
        }
        return streak
    }
    
    private func saveRoutines() {
        guard let data = UserDefaultsStorage.encode(routines) else { return }
        UserDefaultsStorage.save(data, key: Self.routinesKey)
    }
    
    private func loadRoutines() {
        guard let data = UserDefaultsStorage.load(key: Self.routinesKey),
              let decoded = UserDefaultsStorage.decode([Routine].self, from: data) else {
            return
        }
        routines = decoded
    }
}
