import Foundation
import Combine

// MARK: - ルーティンでギフト解禁時の通知（アラート・演出用）
struct RoutineGiftUnlockEvent: Identifiable, Equatable {
    let id: UUID
    let routineId: UUID
    let giftTitle: String
    let routineTitle: String
    
    init(routineId: UUID, giftTitle: String, routineTitle: String) {
        self.id = UUID()
        self.routineId = routineId
        self.giftTitle = giftTitle
        self.routineTitle = routineTitle
    }
}

// MARK: - CalendarDay（カレンダー表示用）
struct CalendarDay: Identifiable {
    let id: String
    let dateString: String
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
    /// 表示対象月に含まれる日（前月・翌月の補完セルは false）
    let isInDisplayedMonth: Bool
}

// MARK: - Routine ViewModel
@MainActor
class RoutineViewModel: ObservableObject {
    @Published var routines: [Routine] = []
    /// ギフト獲得時にセット。表示側で消費して nil に戻す。
    @Published var routineGiftUnlockEvent: RoutineGiftUnlockEvent?
    
    /// ContentView 等から注入（ルーティン完了時のギフト解禁）
    var giftViewModel: GiftViewModel?
    
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
        if let r = routines.first(where: { $0.id == id }), !r.associatedGiftId.isEmpty {
            giftViewModel?.deleteGift(id: r.associatedGiftId)
        }
        routines.removeAll { $0.id == id }
        saveRoutines()
    }
    
    /// 完了トグル。目標回数到達時は紐付きギフトを解禁し `routineGiftUnlockEvent` を発行する。
    func toggleRoutineCompletion(id: UUID, date: String) {
        guard let index = routines.firstIndex(where: { $0.id == id }) else { return }
        var routine = routines[index]
        let wasCompleted = routine.completionHistory.contains(date)
        let target = max(1, routine.targetCount)
        
        if wasCompleted {
            routine.completionHistory.removeAll { $0 == date }
            if routine.currentCycleCount > 0 {
                routine.currentCycleCount -= 1
            }
        } else {
            routine.completionHistory.append(date)
            routine.completionHistory.sort()
            routine.currentCycleCount += 1
            
            if routine.currentCycleCount >= target {
                if !routine.associatedGiftId.isEmpty, let gv = giftViewModel,
                   let unlocked = gv.unlockGiftIfLocked(id: routine.associatedGiftId, publishToLastUnlocked: false) {
                    routineGiftUnlockEvent = RoutineGiftUnlockEvent(
                        routineId: routine.id,
                        giftTitle: unlocked.title,
                        routineTitle: routine.title
                    )
                }
                routine.currentCycleCount = 0
            }
        }
        
        routines[index] = routine
        saveRoutines()
    }
    
    func clearRoutineGiftUnlockEvent() {
        routineGiftUnlockEvent = nil
    }
    
    /// カレンダー表示用（日曜始まり・当月の1日位置に合わせた月グリッド。前月・翌月を補完）
    /// - Parameters:
    ///   - routine: 完了履歴を参照するルーティン
    ///   - referenceMonth: 表示する月の基準日（その日が含まれる月を表示）
    func generateCalendarData(for routine: Routine, referenceMonth: Date = Date()) -> [CalendarDay] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let ymd = calendar.dateComponents([.year, .month], from: referenceMonth)
        guard let monthStartRaw = calendar.date(from: ymd) else { return [] }
        let monthStart = calendar.startOfDay(for: monthStartRaw)
        
        guard let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count else { return [] }
        
        // 1日の曜日: 1=日 … 7=土。日曜を列0に合わせるため、その週の日曜からグリッド開始
        let weekdayOfFirst = calendar.component(.weekday, from: monthStart)
        let leadingCount = weekdayOfFirst - 1
        
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingCount, to: monthStart) else { return [] }
        let gridStartDay = calendar.startOfDay(for: gridStart)
        
        let bodyCellCount = leadingCount + daysInMonth
        let trailingCount = (7 - (bodyCellCount % 7)) % 7
        let totalCells = bodyCellCount + trailingCount
        
        var result: [CalendarDay] = []
        result.reserveCapacity(totalCells)
        
        for offset in 0..<totalCells {
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStartDay) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dateString = formatter.string(from: dayStart)
            let isCompleted = routine.completionHistory.contains(dateString)
            let isToday = calendar.isDate(dayStart, inSameDayAs: today)
            let isInDisplayedMonth = calendar.isDate(dayStart, equalTo: monthStart, toGranularity: .month)
            
            result.append(CalendarDay(
                id: dateString,
                dateString: dateString,
                date: dayStart,
                isCompleted: isCompleted,
                isToday: isToday,
                isInDisplayedMonth: isInDisplayedMonth
            ))
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
