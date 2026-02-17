import SwiftUI

// MARK: - Gift Card View (Glassmorphism + Locked/Unlocked)
struct GiftCardView: View {
    var gift: Gift
    var onUnlock: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    
    @State private var isUnlocking = false
    @State private var didPlayUnlockFeedback = false
    @State private var showCelebration = false
    
    var body: some View {
        cardContent
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: gift.status)
            .onChange(of: gift.status) { oldValue, newValue in
                if oldValue == .locked && newValue == .unlocked {
                    if !didPlayUnlockFeedback {
                        HapticManager.shared.giftUnlocked()
                        didPlayUnlockFeedback = true
                    }
                    if (gift.effectiveRewardUrl ?? "").isEmpty {
                        showCelebration = true
                    }
                }
            }
            .sheet(isPresented: $showCelebration) {
                CelebrationModal(message: "おめでとう🎉", subtitle: gift.title)
            }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ヘッダー
            HStack {
                // タイトル
                Text(gift.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(gift.status == .locked ? .white.opacity(0.7) : .primary)
                    .lineLimit(2)
                
                Spacer()
                
                if gift.status == .locked {
                    HStack(spacing: 12) {
                        if onEdit != nil {
                            Button {
                                onEdit?()
                            } label: {
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
            
            // 説明
            if let description = gift.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(gift.status == .locked ? .white.opacity(0.6) : .secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // フッター
            HStack {
                // 価格
                VStack(alignment: .leading, spacing: 4) {
                    Text("¥\(Int(gift.price))")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(gift.status == .locked ? .white.opacity(0.8) : .primary)
                    
                    Text(gift.currency)
                        .font(.system(size: 12))
                        .foregroundColor(gift.status == .locked ? .white.opacity(0.5) : .secondary)
                }
                
                Spacer()
                
                // ステータス（ロック解除時: rewardUrl があれば「利用する」でブラウザ、なければおめでとうモーダル）
                if gift.status == .unlocked {
                    if let urlString = gift.effectiveRewardUrl, !urlString.isEmpty, let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack(spacing: 8) {
                                Text("利用する")
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    } else {
                        Button {
                            showCelebration = true
                        } label: {
                            HStack(spacing: 8) {
                                Text("見る")
                                    .font(.system(size: 14, weight: .semibold))
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                } else {
                    // ロック済み表示
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                        Text("ロック済み")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(gift.status == .locked ? 0.4 : 0))
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
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            // アンロック中のオーバーレイ
            Group {
                if isUnlocking {
                    Color.black.opacity(0.5)
                        .cornerRadius(20)
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
        )
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

