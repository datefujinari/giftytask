import SwiftUI
import FirebaseAuth

// MARK: - Gift List View (ギフトBOX)
struct GiftListView: View {
    @EnvironmentObject var giftViewModel: GiftViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var activityViewModel: ActivityViewModel
    @EnvironmentObject var epicViewModel: EpicViewModel
    @State private var selectedFilter: GiftFilter = .all
    @State private var showAddGift = false
    @State private var editingGift: Gift?
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
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
                        List {
                            ForEach(filteredGifts) { gift in
                                GiftCardView(
                                    gift: gift,
                                    onEdit: canEdit(gift) ? { editingGift = gift } : nil,
                                    onUse: { giftViewModel.useGift($0) }
                                )
                                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        giftViewModel.deleteGift(gift)
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
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
                
                // FAB: ギフト新規追加（オレンジ系でタスクの＋と区別）
                AddTaskFAB(action: {
                    HapticManager.shared.mediumImpact()
                    showAddGift = true
                }, tint: .orange)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .sheet(isPresented: $showAddGift) {
                CreateAssignmentView(isPresented: $showAddGift)
                    .environmentObject(taskViewModel)
                    .environmentObject(giftViewModel)
            }
            .sheet(item: $editingGift, onDismiss: { editingGift = nil }) { gift in
                AddGiftView(isPresented: .constant(true), editingGift: gift)
                    .environmentObject(giftViewModel)
                    .environmentObject(taskViewModel)
                    .environmentObject(activityViewModel)
                    .environmentObject(epicViewModel)
            }
            .sheet(isPresented: Binding(
                get: { giftViewModel.lastUsedGiftTitle != nil },
                set: { if !$0 { giftViewModel.lastUsedGiftTitle = nil } }
            )) {
                GiftReceivedModal(
                    title: giftViewModel.lastUsedGiftTitle ?? "",
                    onDismiss: { giftViewModel.lastUsedGiftTitle = nil }
                )
            }
        }
    }
}

private extension GiftListView {
    func canEdit(_ gift: Gift) -> Bool {
        guard let uid = currentUserId else { return false }
        if let createdByUserId = gift.createdByUserId {
            return createdByUserId == uid
        }
        return gift.type == .selfReward
    }
}

// MARK: - Preview
#Preview {
    GiftListView()
        .environmentObject(GiftViewModel())
        .environmentObject(TaskViewModel())
        .environmentObject(ActivityViewModel())
        .environmentObject(EpicViewModel())
}

