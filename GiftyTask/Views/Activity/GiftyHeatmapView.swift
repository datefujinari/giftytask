import SwiftUI

/// GitHub風アクティビティヒートマップ
struct GiftyHeatmapView: View {
    let heatmapData: [HeatmapData]
    @Binding var theme: HeatmapTheme
    
    /// 週ごとにグループ化（日曜始まり）
    private var weeklyData: [[HeatmapData]] {
        var weeks: [[HeatmapData]] = []
        var currentWeek: [HeatmapData] = []
        let calendar = Calendar.current
        
        for data in heatmapData.sorted(by: { $0.date < $1.date }) {
            let weekday = calendar.component(.weekday, from: data.date)
            if weekday == 1 && !currentWeek.isEmpty {
                weeks.append(currentWeek)
                currentWeek = []
            }
            currentWeek.append(data)
        }
        if !currentWeek.isEmpty { weeks.append(currentWeek) }
        return weeks.reversed()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("アクティビティヒートマップ")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                ColorPicker("", selection: themeColorBinding)
                    .labelsHidden()
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, week in
                        VStack(spacing: 4) {
                            ForEach(week, id: \.date) { data in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(theme.color(for: data.intensity))
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                    )
                                    .help("\(data.date.formatted(date: .abbreviated, time: .omitted)): \(data.intensity) level")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 4) {
                Text("少ない")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                ForEach(0...4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.color(for: level))
                        .frame(width: 10, height: 10)
                }
                Text("多い")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var themeColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: theme.baseColorHex) },
            set: { newColor in
                var t = theme
                t.baseColorHex = newColor.toHex() ?? "#34C759"
                theme = t
            }
        )
    }
}

// MARK: - Color Hex 変換
extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
