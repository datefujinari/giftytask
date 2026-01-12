# GiftyTask - アーキテクチャ設計

## 1. システム構成概要

### クライアント側（SwiftUI / iOS）

```
GiftyTask/
├── App/
│   ├── GiftyTaskApp.swift          # アプリエントリーポイント
│   └── AppDelegate.swift            # ライフサイクル管理
├── Models/
│   ├── Task.swift                   # タスクデータモデル
│   ├── Epic.swift                   # エピックデータモデル
│   ├── Gift.swift                   # ギフトデータモデル
│   ├── User.swift                   # ユーザーデータモデル
│   └── ActivityData.swift           # アクティビティデータモデル
├── Views/
│   ├── Task/
│   │   ├── TaskCardView.swift       # Glassmorphismタスクカード
│   │   ├── TaskDetailView.swift     # タスク詳細
│   │   └── TaskListView.swift       # タスク一覧
│   ├── Epic/
│   │   ├── EpicCardView.swift       # エピックカード
│   │   └── EpicDetailView.swift     # エピック詳細
│   ├── Gift/
│   │   ├── GiftCardView.swift       # ロック済みギフトカード
│   │   └── GiftUnlockView.swift     # ギフトアンロックアニメーション
│   ├── Activity/
│   │   ├── ActivityRingView.swift   # アクティビティリング
│   │   └── HeatmapView.swift        # ヒートマップ表示
│   ├── Social/
│   │   ├── FriendListView.swift     # フレンド一覧
│   │   └── GiftAssignmentView.swift # ギフト送信
│   └── Settings/
│       └── SettingsView.swift       # 設定画面
├── ViewModels/
│   ├── TaskViewModel.swift          # タスク管理ロジック
│   ├── EpicViewModel.swift          # エピック管理ロジック
│   ├── GiftViewModel.swift          # ギフト管理ロジック
│   └── ActivityViewModel.swift      # アクティビティ計算ロジック
├── Services/
│   ├── FirebaseService.swift        # Firebase統合
│   ├── GifteeAPIService.swift       # giftee API統合
│   ├── PaymentService.swift         # Apple Pay/Stripe統合
│   ├── CameraService.swift          # カメラ機能
│   └── NotificationService.swift    # ローカル通知
├── Utilities/
│   ├── GlassmorphismModifier.swift  # Glassmorphismスタイル
│   ├── HapticManager.swift          # Taptic Engine管理
│   └── ThemeManager.swift           # テーマ管理（レベル別）
└── Resources/
    ├── Assets.xcassets/             # アセット
    └── Localizable.strings          # ローカライズ
```

### バックエンド（Firebase + API）

```
Backend Services:
├── Firebase Firestore
│   ├── Collections/
│   │   ├── users/                   # ユーザープロフィール
│   │   ├── tasks/                   # タスクデータ
│   │   ├── epics/                   # エピックデータ
│   │   ├── gifts/                   # ギフトデータ（ロック状態含む）
│   │   ├── activities/              # アクティビティ記録
│   │   └── friendships/             # フレンド関係
│   └── Security Rules
│       └── firestore.rules          # データアクセス制御
├── Firebase Authentication
│   ├── Sign in with Apple
│   └── Email/Password
├── Firebase Cloud Functions
│   ├── onTaskComplete/              # タスク完了時の処理
│   ├── unlockGift/                  # ギフトアンロック処理
│   ├── calculateXP/                 # XP計算
│   └── sendNotification/            # 通知送信
├── giftee API Integration
│   ├── Gift Catalog                 # ギフトカタログ取得
│   ├── Gift Creation                # ギフト作成
│   └── Gift Redemption              # ギフト引き換え
└── Payment Gateway
    ├── Apple Pay Integration
    └── Stripe Integration
```

## 2. データフロー

### タスク完了フロー

```
1. User completes task (tap/long-press)
   ↓
2. CameraService captures photo (if long-press)
   ↓
3. TaskViewModel updates task status
   ↓
4. FirebaseService syncs to Firestore
   ↓
5. Cloud Function triggers:
   - Calculate XP gain
   - Check gift unlock conditions
   - Update activity rings
   - Update heatmap data
   ↓
6. If gift unlocked:
   - PaymentService processes payment
   - GifteeAPIService creates gift
   - GiftViewModel triggers unlock animation
   ↓
7. HapticManager provides feedback
   ↓
8. UI updates with animation
```

### ギフト送信フロー（ソーシャル）

```
1. User selects friend from FriendListView
   ↓
2. User assigns task and gift
   ↓
3. GiftViewModel creates locked gift
   ↓
4. FirebaseService stores gift assignment
   ↓
5. NotificationService notifies friend
   ↓
6. Friend completes task
   ↓
7. Gift unlocks for friend (payment processed at unlock)
```

## 3. 主要技術スタック

### クライアント
- **SwiftUI**: UI構築
- **Combine**: リアクティブプログラミング
- **Core Data** (オプション): オフラインキャッシュ
- **Camera**: AVFoundation
- **Haptics**: UIKit Haptic Engine

### バックエンド
- **Firebase Firestore**: データベース
- **Firebase Authentication**: 認証
- **Firebase Cloud Functions**: サーバーレスロジック
- **Firebase Cloud Messaging**: プッシュ通知
- **giftee API**: ギフト管理
- **Stripe API**: 決済処理

### 外部API
- **giftee API**: ギフトカタログ、ギフト作成
- **Stripe API**: 決済処理（Apple Pay経由も含む）

## 4. セキュリティ考慮事項

1. **認証**: Firebase Authentication + Sign in with Apple
2. **データアクセス**: Firestore Security Rules でフレンド関係に基づく制限
3. **決済**: トークン化された決済情報のみ送信
4. **写真**: 写真はFirebase Storageに暗号化保存
5. **API Keys**: 機密情報はFirebase Config/Environment Variablesで管理

## 5. パフォーマンス最適化

1. **オフラインサポート**: Firestoreオフライン永続化
2. **画像最適化**: 写真はサムネイル生成・キャッシュ
3. **レイジーローディング**: ヒートマップ・アクティビティリングは必要時のみ計算
4. **バッチ処理**: 複数タスク更新はバッチ処理

