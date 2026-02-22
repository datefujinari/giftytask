import Foundation

// MARK: - UserDefaults 永続化ヘルパー（Date を ISO8601 で保存）
enum UserDefaultsStorage {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
    
    enum Key {
        static let tasks = "gifty_persist_tasks"
        static let gifts = "gifty_persist_gifts"
        static let epics = "gifty_persist_epics"
        static let dailyActivityData = "gifty_persist_daily_activity"
        static let streakData = "gifty_persist_streak_data"
        static let currentUser = "gifty_persist_current_user"
        static let heatmapTheme = "gifty_persist_heatmap_theme"
    }
    
    static func encode<T: Encodable>(_ value: T) -> Data? {
        try? encoder.encode(value)
    }
    
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
        try? decoder.decode(type, from: data)
    }
    
    static func save(_ data: Data, key: String) {
        UserDefaults.standard.set(data, forKey: key)
    }
    
    static func load(key: String) -> Data? {
        UserDefaults.standard.data(forKey: key)
    }
    
    static func hasData(key: String) -> Bool {
        UserDefaults.standard.data(forKey: key) != nil
    }
}
