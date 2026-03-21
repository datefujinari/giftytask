import SwiftUI

// MARK: - Routine List View
struct RoutineListView: View {
    @EnvironmentObject var routineViewModel: RoutineViewModel
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
    
    private var routineList: some View {
        List {
            ForEach(routineViewModel.routines.sorted(by: { $0.order < $1.order })) { routine in
                NavigationLink(destination: RoutineDetailView(routine: routine)) {
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
                        }
                        
                        Spacer()
                        
                        Text("\(routine.points)pt")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(secondaryColor.opacity(0.5))
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
