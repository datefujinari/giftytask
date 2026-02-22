import Foundation
import SwiftUI

// MARK: - ActivityData ヒートマップ拡張
extension ActivityData {
    /// GitHub風の5段階レベルを計算 (0: なし, 1-4: 完了数に応じた濃度)
    var heatmapLevel: Int {
        switch completedTasksCount {
        case 0: return 0
        case 1...2: return 1
        case 3...5: return 2
        case 6...9: return 3
        default: return 4
        }
    }
}

// MARK: - HeatmapTheme（カスタマイズ可能なカラー設定）
struct HeatmapTheme: Codable {
    var baseColorHex: String = "#34C759"
    
    func color(for level: Int) -> Color {
        let base = Color(hex: baseColorHex)
        switch level {
        case 0: return Color(UIColor.systemGray6)
        case 1: return base.opacity(0.3)
        case 2: return base.opacity(0.5)
        case 3: return base.opacity(0.7)
        case 4: return base
        default: return Color(UIColor.systemGray6)
        }
    }
}
