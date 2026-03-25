import SwiftUI

// MARK: - 受信BOX View（届いた提案を一覧・受け入れ）
struct ReceivedBoxView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var giftViewModel: GiftViewModel
    @EnvironmentObject var routineViewModel: RoutineViewModel
    @State private var showCreateAssignment = false
    @State private var showApprovalPending = false
    @State private var acceptingTaskId: String?
    @State private var acceptingRoutineId: String?
    
    private var pendingTasks: [FirestoreTaskDTO] { taskViewModel.pendingReceivedTasks }
    private var pendingRoutines: [FirestoreRoutineSuggestionDTO] {
        routineViewModel.receivedRoutineSuggestions.filter { $0.status == "pending" }
    }
    private var pendingApprovalCount: Int { taskViewModel.pendingApprovalTasks.count }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    if pendingTasks.isEmpty && pendingRoutines.isEmpty && pendingApprovalCount == 0 {
                        EmptyStateView(
                            icon: "tray",
                            title: "届いた提案はありません",
                            message: "タスクやルーティン提案が届くとここに表示されます"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                if pendingApprovalCount > 0 {
                                    Button {
                                        showApprovalPending = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("承認待ち (\(pendingApprovalCount)件)")
                                                .fontWeight(.medium)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .padding()
                                        .background(Color.orange.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal)
                                }
                                
                                ForEach(pendingTasks) { dto in
                                    ReceivedTaskCardView(
                                        dto: dto,
                                        isAccepting: acceptingTaskId == dto.id,
                                        onAccept: {
                                            _Concurrency.Task { @MainActor in
                                                acceptingTaskId = dto.id
                                                defer { acceptingTaskId = nil }
                                                do {
                                                    try await taskViewModel.acceptReceivedTask(dto, giftViewModel: giftViewModel)
                                                } catch {
                                                    taskViewModel.errorMessage = error.localizedDescription
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                                
                                ForEach(pendingRoutines) { suggestion in
                                    ReceivedRoutineSuggestionCardView(
                                        suggestion: suggestion,
                                        isAccepting: acceptingRoutineId == suggestion.id,
                                        onAccept: {
                                            _Concurrency.Task { @MainActor in
                                                acceptingRoutineId = suggestion.id
                                                defer { acceptingRoutineId = nil }
                                                do {
                                                    try await routineViewModel.acceptRoutineSuggestion(suggestion)
                                                } catch {
                                                    taskViewModel.errorMessage = error.localizedDescription
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .navigationTitle("受信BOX")
                .toolbar {
                    if pendingApprovalCount > 0 {
                        ToolbarItem(placement: .primaryAction) {
                            Button("承認待ち \(pendingApprovalCount)") {
                                showApprovalPending = true
                            }
                        }
                    }
                }
                .background(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                // ルーティン提案の購読は ContentView でログイン後に開始済み（ここではタスク購読の再同期のみ）
                .task {
                    await taskViewModel.loadTasks()
                }
                
                Button {
                    HapticManager.shared.mediumImpact()
                    showCreateAssignment = true
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .sheet(isPresented: $showCreateAssignment) {
                CreateAssignmentView(isPresented: $showCreateAssignment)
                    .environmentObject(taskViewModel)
                    .environmentObject(giftViewModel)
            }
            .sheet(isPresented: $showApprovalPending) {
                ApprovalPendingView()
                    .environmentObject(taskViewModel)
            }
        }
    }
}

// MARK: - 受信BOX用カード（タスク）
struct ReceivedTaskCardView: View {
    let dto: FirestoreTaskDTO
    var isAccepting: Bool = false
    var onAccept: () -> Void
    
    private var senderDisplayName: String { dto.senderName ?? "匿名ユーザー" }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("From:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(senderDisplayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(dto.senderTotalCompletedCount)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.accentColor)
                    Text("達成")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Text(dto.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            if let name = dto.giftName, !name.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "gift.fill")
                        .font(.caption)
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Button(action: onAccept) {
                HStack {
                    if isAccepting {
                        ProgressView().tint(.white)
                    } else {
                        Text("受け入れる")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isAccepting)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.12))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - 受信BOX用カード（ルーティン）
struct ReceivedRoutineSuggestionCardView: View {
    let suggestion: FirestoreRoutineSuggestionDTO
    var isAccepting: Bool = false
    var onAccept: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("From: \(suggestion.senderName ?? "匿名ユーザー")")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("ルーティン")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(8)
            }
            Text(suggestion.title)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(2)
            if let desc = suggestion.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 6) {
                Image(systemName: "gift.fill")
                    .font(.caption)
                Text(suggestion.associatedGiftName)
                    .font(.subheadline)
                Spacer()
                Text("\(max(1, suggestion.targetCount))日")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.secondary)
            
            Button(action: onAccept) {
                HStack {
                    if isAccepting {
                        ProgressView().tint(.white)
                    } else {
                        Text("受け入れる")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isAccepting)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.12))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
