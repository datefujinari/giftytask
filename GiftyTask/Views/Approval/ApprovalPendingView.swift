import SwiftUI

// MARK: - 承認待ち一覧（送信者用：完了報告されたタスクを承認 or 差し戻し）
struct ApprovalPendingView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var approvingId: String?
    @State private var rejectingId: String?
    
    private var pending: [FirestoreTaskDTO] {
        taskViewModel.pendingApprovalTasks
    }
    
    var body: some View {
        NavigationView {
            Group {
                if pending.isEmpty {
                    EmptyStateView(
                        icon: "checkmark.circle",
                        title: "承認待ちはありません",
                        message: "完了報告が届くとここに表示されます"
                    )
                } else {
                    List {
                        ForEach(pending) { dto in
                            ApprovalPendingCardView(
                                dto: dto,
                                isApproving: approvingId == dto.id,
                                isRejecting: rejectingId == dto.id,
                                onApprove: { await approve(dto) },
                                onReject: { await reject(dto) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("承認待ち")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
    
    private func approve(_ dto: FirestoreTaskDTO) async {
        approvingId = dto.id
        defer { approvingId = nil }
        do {
            try await taskViewModel.approveTaskCompletion(dto)
            dismiss()
        } catch {
            taskViewModel.errorMessage = error.localizedDescription
        }
    }
    
    private func reject(_ dto: FirestoreTaskDTO) async {
        rejectingId = dto.id
        defer { rejectingId = nil }
        do {
            try await taskViewModel.rejectTaskCompletion(dto)
        } catch {
            taskViewModel.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - 承認待ちカード（報告画像・承認/差し戻しボタン）
struct ApprovalPendingCardView: View {
    let dto: FirestoreTaskDTO
    var isApproving: Bool = false
    var isRejecting: Bool = false
    var onApprove: () async -> Void
    var onReject: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dto.title)
                .font(.headline)
            if let urlString = dto.completionImageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        placeholderImage
                    case .empty:
                        placeholderImage
                            .overlay(ProgressView())
                    @unknown default:
                        placeholderImage
                    }
                }
                .frame(minHeight: 120)
            } else {
                placeholderImage
            }
            HStack(spacing: 12) {
                Button {
                    _Concurrency.Task { await onReject() }
                } label: {
                    HStack {
                        if isRejecting {
                            ProgressView().tint(.white)
                        } else {
                            Text("差し戻し")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isApproving || isRejecting)
                Button {
                    _Concurrency.Task { await onApprove() }
                } label: {
                    HStack {
                        if isApproving {
                            ProgressView().tint(.white)
                        } else {
                            Text("承認")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isApproving || isRejecting)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .frame(height: 120)
            .overlay(
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            )
    }
}
