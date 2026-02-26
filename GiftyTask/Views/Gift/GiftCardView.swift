import SwiftUI

// MARK: - Gift Card View (Glassmorphism + Locked/Unlocked)
struct GiftCardView: View {
    var gift: Gift
    var onUnlock: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onUse: ((Gift) -> Void)? = nil
    
    @State private var isUnlocking = false
    @State private var didPlayUnlockFeedback = false
    @State private var showReceiptModal = false
    @State private var showUseConfirmModal = false
    @State private var showReceiveConfirmModal = false
    
    @ViewBuilder
    private func actionButtonContent(text: String, icon: String, isGreen: Bool = false) -> some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 14, weight: .semibold))
            Image(systemName: icon)
                .font(.system(size: 16))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: isGreen ? [Color.green, Color.green.opacity(0.8)] : [Color.blue, Color.purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
    
    var body: some View {
        cardContent
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: gift.status)
            .onChange(of: gift.status) { oldValue, newValue in
                if oldValue == .locked && newValue == .unlocked {
                    if !didPlayUnlockFeedback {
                        HapticManager.shared.giftUnlocked()
                        didPlayUnlockFeedback = true
                    }
                }
            }
            .sheet(isPresented: $showUseConfirmModal) {
                UseConfirmModal(
                    onYes: {
                        showUseConfirmModal = false
                        onUse?(gift)
                    },
                    onNo: { showUseConfirmModal = false }
                )
            }
            .sheet(isPresented: $showReceiveConfirmModal) {
                ReceiveConfirmModal(
                    onYes: {
                        showReceiveConfirmModal = false
                        performReceiveAction()
                    },
                    onNo: { showReceiveConfirmModal = false }
                )
            }
            .sheet(isPresented: $showReceiptModal) {
                let msg = (gift.receiptMessage ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                CelebrationModal(
                    message: msg.isEmpty ? "ギフトを獲得しました！" : msg,
                    subtitle: gift.title
                )
            }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            if let description = gift.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(gift.status == .locked ? .white.opacity(0.6) : .secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 16)
            footerView
        }
        .padding(24)
        .frame(minHeight: 220)
        .frame(maxWidth: .infinity)
        .background(cardBackgroundShape)
        .overlay(unlockingOverlay)
    }
    
    private var headerView: some View {
        HStack {
            Text(gift.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(gift.status == .locked ? .white.opacity(0.7) : .primary)
                .lineLimit(2)
            Spacer()
            if gift.status == .locked {
                HStack(spacing: 12) {
                    if onEdit != nil {
                        Button { onEdit?() } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("¥\(Int(gift.price))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(gift.status == .locked ? .white.opacity(0.8) : .primary)
                    Text(gift.currency)
                        .font(.system(size: 12))
                        .foregroundColor(gift.status == .locked ? .white.opacity(0.5) : .secondary)
                }
                Spacer()
                if let fromId = gift.assignedFromUserId, !fromId.isEmpty {
                    Text("From: \(fromId)")
                        .font(.system(size: 12))
                        .foregroundColor(gift.status == .locked ? .white.opacity(0.6) : .secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            footerButtons
        }
    }
    
    @ViewBuilder
    private var footerButtons: some View {
        HStack(spacing: 12) {
            Spacer()
            if gift.status == .unlocked {
                if let urlString = gift.effectiveRewardUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                    Link(destination: url) {
                        actionButtonContent(text: "確認する", icon: "arrow.right.circle.fill")
                    }
                    .frame(width: 100, height: 44)
                    Button { onReceiveTapped() } label: {
                        actionButtonContent(text: "受け取る", icon: "checkmark.circle.fill", isGreen: true)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 100, height: 44)
                } else {
                    Button { showReceiptModal = true } label: {
                        actionButtonContent(text: "見る", icon: "gift.fill")
                    }
                    .buttonStyle(.plain)
                    .frame(width: 100, height: 44)
                    Button { showUseConfirmModal = true } label: {
                        actionButtonContent(text: "使う", icon: "checkmark.circle.fill", isGreen: true)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 100, height: 44)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    Text("ロック済み")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 120, height: 44)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }
    
    private var cardBackgroundShape: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(gift.status == .locked ? 0.4 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(gift.status == .locked ? 0.3 : 0.6),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    /// 「受け取る」ボタン押下時（URLありのギフト用・将来独立して変更可能）
    private func onReceiveTapped() {
        showReceiveConfirmModal = true
    }
    
    /// 受け取り処理（現状は「使う」と同じ動作）
    private func performReceiveAction() {
        onUse?(gift)
    }
    
    @ViewBuilder
    private var unlockingOverlay: some View {
        if isUnlocking {
            Color.black.opacity(0.5)
                .cornerRadius(20)
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
        }
    }
}

// MARK: - 受け取り確認モーダル（URLありギフトの「受け取る」用）
struct ReceiveConfirmModal: View {
    let onYes: () -> Void
    let onNo: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("本当に受け取りますか？")
                .font(.system(size: 20, weight: .semibold))
            HStack(spacing: 16) {
                Button("いいえ") {
                    onNo()
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                Button("はい") {
                    onYes()
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
        }
        .padding(40)
    }
}

// MARK: - 使用確認モーダル
struct UseConfirmModal: View {
    let onYes: () -> Void
    let onNo: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("本当に使用しますか？")
                .font(.system(size: 20, weight: .semibold))
            HStack(spacing: 16) {
                Button("いいえ") {
                    onNo()
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .cornerRadius(12)
                Button("はい") {
                    onYes()
                    dismiss()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
        }
        .padding(40)
    }
}

// MARK: - ギフト受け取り完了モーダル
struct GiftReceivedModal: View {
    let title: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
                .padding(.top, 8)
            }
            Spacer()
            Text("ギフトを受け取りました")
                .font(.system(size: 24, weight: .bold))
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(24)
    }
}

// MARK: - おめでとうモーダル（rewardUrl が空の解禁時）
struct CelebrationModal: View {
    let message: String
    var subtitle: String? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text(message)
                .font(.system(size: 28, weight: .bold))
            if let subtitle = subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
            Button("閉じる") {
                dismiss()
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(12)
        }
        .padding(40)
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // ロック済みギフト
            GiftCardView(gift: PreviewContainer.mockGifts[0])
            
            GiftCardView(gift: PreviewContainer.mockGifts[1])
            
            // アンロック済みギフト
            GiftCardView(gift: PreviewContainer.mockGifts[3])
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}

