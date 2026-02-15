import SwiftUI

// MARK: - Gift Card View (Glassmorphism + Locked/Unlocked)
struct GiftCardView: View {
    var gift: Gift
    var onUnlock: (() -> Void)? = nil
    
    @State private var isUnlocking = false
    @State private var didPlayUnlockFeedback = false
    
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
                
                // ロックアイコン
                if gift.status == .locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.6))
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
                
                // ステータス（ロック解除で「利用する」に切り替わり＋パリンと割れるアニメーション）
                if gift.status == .unlocked {
                    let urlString = gift.giftURL ?? Gift.defaultGiftURL
                    if let url = URL(string: urlString) {
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

