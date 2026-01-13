import SwiftUI

// MARK: - Gift List View (ギフトBOX)
struct GiftListView: View {
    @State private var gifts: [Gift]
    @State private var selectedFilter: GiftFilter = .all
    
    enum GiftFilter: String, CaseIterable {
        case all = "全て"
        case locked = "ロック済み"
        case unlocked = "アンロック済み"
    }
    
    init(gifts: [Gift] = PreviewContainer.mockGifts) {
        _gifts = State(initialValue: gifts)
    }
    
    var filteredGifts: [Gift] {
        switch selectedFilter {
        case .all:
            return gifts
        case .locked:
            return gifts.filter { $0.status == .locked }
        case .unlocked:
            return gifts.filter { $0.status == .unlocked || $0.status == .redeemed }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // フィルタ
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(GiftFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // ギフト一覧
                if filteredGifts.isEmpty {
                    EmptyStateView(
                        icon: "gift.fill",
                        title: "ギフトがありません",
                        message: selectedFilter == .locked ? "アンロック済みギフトはまだありません" : "新しいギフトを獲得しましょう"
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredGifts) { gift in
                                GiftCardView(gift: gift)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("ギフトBOX")
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

// MARK: - Preview
#Preview {
    GiftListView(gifts: PreviewContainer.mockGifts)
}

