import SwiftUI

// MARK: - Gift List View (ギフトBOX)
struct GiftListView: View {
    @EnvironmentObject var giftViewModel: GiftViewModel
    @State private var selectedFilter: GiftFilter = .all
    @State private var showAddGift = false
    
    enum GiftFilter: String, CaseIterable {
        case all = "全て"
        case locked = "ロック済み"
        case unlocked = "アンロック済み"
    }
    
    var filteredGifts: [Gift] {
        switch selectedFilter {
        case .all:
            return giftViewModel.gifts
        case .locked:
            return giftViewModel.gifts.filter { $0.status == .locked }
        case .unlocked:
            return giftViewModel.gifts.filter { $0.status == .unlocked || $0.status == .redeemed }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
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
                .onAppear {
                    giftViewModel.loadGifts()
                }
                
                // FAB: ギフト新規追加（タスク画面と統一デザイン）
                AddTaskFAB {
                    HapticManager.shared.mediumImpact()
                    showAddGift = true
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .sheet(isPresented: $showAddGift) {
                AddGiftView(isPresented: $showAddGift)
                    .environmentObject(giftViewModel)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    GiftListView()
        .environmentObject(GiftViewModel())
}

