import SwiftUI

// MARK: - Routine List View
struct RoutineListView: View {
    @EnvironmentObject var routineViewModel: RoutineViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    @State private var showAddRoutine = false
    
    private let primaryColor = Color(hex: "#4F46E5")
    private let secondaryColor = Color(hex: "#6B7280")
    private let backgroundGradient = LinearGradient(
        colors: [Color.white, Color(hex: "#F0F4FF")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                if routineViewModel.routines.isEmpty {
                    emptyState
                } else {
                    routineList
                }
                
                AddTaskFAB(action: {
                    HapticManager.shared.mediumImpact()
                    showAddRoutine = true
                }, tint: primaryColor)
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .background(backgroundGradient)
            .navigationTitle("ルーティン一覧")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("全 \(routineViewModel.routines.count) 件")
                        .font(.subheadline)
                        .foregroundColor(secondaryColor)
                }
            }
            .sheet(isPresented: $showAddRoutine) {
                AddRoutineSheet(isPresented: $showAddRoutine)
                    .environmentObject(routineViewModel)
                    .environmentObject(giftViewModel)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 60))
                .foregroundColor(secondaryColor.opacity(0.5))
            Text("ルーティンがありません")
                .font(.title2.weight(.semibold))
                .foregroundColor(.primary)
            Text("＋ボタンから新しいルーティンを追加しましょう")
                .font(.subheadline)
                .foregroundColor(secondaryColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func giftDisplayTitle(for routine: Routine) -> String {
        guard !routine.associatedGiftId.isEmpty,
              let g = giftViewModel.gifts.first(where: { $0.id == routine.associatedGiftId }) else {
            return "ギフト未設定"
        }
        return g.title
    }
    
    private var routineList: some View {
        List {
            ForEach(routineViewModel.routines.sorted(by: { $0.order < $1.order })) { routine in
                NavigationLink(destination: RoutineDetailView(routine: routine)
                    .environmentObject(routineViewModel)
                    .environmentObject(giftViewModel)) {
                    HStack(spacing: 12) {
                        Image(systemName: routine.isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(routine.isCompletedToday ? primaryColor : secondaryColor.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)
                            if let desc = routine.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.system(size: 14))
                                    .foregroundColor(secondaryColor)
                                    .lineLimit(2)
                            }
                            HStack(spacing: 6) {
                                Text("🎁 \(giftDisplayTitle(for: routine))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(primaryColor)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(routine.currentCycleCount)/\(max(1, routine.targetCount))日")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(secondaryColor)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(secondaryColor.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.white.opacity(0.8))
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
