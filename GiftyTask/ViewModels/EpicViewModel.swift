import Foundation

// MARK: - Epic ViewModel（永続化対応）
@MainActor
class EpicViewModel: ObservableObject {
    @Published var epics: [Epic] = []
    
    init(epics: [Epic] = []) {
        if !epics.isEmpty {
            self.epics = epics
        } else {
            loadData()
        }
    }
    
    func saveData() {
        guard let data = UserDefaultsStorage.encode(epics) else { return }
        UserDefaultsStorage.save(data, key: UserDefaultsStorage.Key.epics)
    }
    
    func loadData() {
        guard let data = UserDefaultsStorage.load(key: UserDefaultsStorage.Key.epics),
              let decoded = UserDefaultsStorage.decode([Epic].self, from: data) else {
            return
        }
        self.epics = decoded
    }
    
    func addEpic(_ epic: Epic) {
        epics.append(epic)
        saveData()
    }
    
    func updateEpic(_ epic: Epic) {
        guard let index = epics.firstIndex(where: { $0.id == epic.id }) else { return }
        var updated = epic
        updated.updatedAt = Date()
        epics[index] = updated
        saveData()
    }
    
    func deleteEpic(_ epic: Epic) {
        epics.removeAll { $0.id == epic.id }
        saveData()
    }
    
    /// ローカルデータを初期状態にリセット
    func resetData() {
        epics = []
        saveData()
    }
}
