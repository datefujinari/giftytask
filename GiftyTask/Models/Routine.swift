import Foundation

// MARK: - Routine Model
struct Routine: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var points: Int
    var order: Int
    var completionHistory: [String] // ISO 8601形式の日付文字列（YYYY-MM-DD）
    
    /// 今日の日付がcompletionHistoryに含まれているか
    var isCompletedToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let todayString = formatter.string(from: Date())
        return completionHistory.contains(todayString)
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        points: Int = 10,
        order: Int = 0,
        completionHistory: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.points = points
        self.order = order
        self.completionHistory = completionHistory
    }
}
