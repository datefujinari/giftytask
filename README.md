# GiftyTask - iOS Task Management App

「努力を価値に変える」をコンセプトにした、ゲーミフィケーションとeギフトを融合させたiOS向けタスク管理アプリ「GiftyTask」の開発用雛形。

## プロジェクト構成

```
GiftyTask/
├── DOCUMENTATION.md         # 開発ドキュメント（セットアップ・アーキテクチャ・トラブルシューティング）
├── README.md                # このファイル
├── Models/                  # データモデル
│   ├── Task.swift
│   ├── Epic.swift
│   ├── Gift.swift
│   ├── User.swift
│   └── ActivityData.swift
├── Views/                   # SwiftUI ビュー
│   ├── Activity/
│   │   └── ActivityRingView.swift
│   └── Task/
│       └── TaskCardView.swift
└── Utilities/               # ユーティリティ
    ├── GlassmorphismModifier.swift
    └── HapticManager.swift
```

## 主要機能

### 1. タスク管理
- **Epic（大目標）**: 複数の子タスクを含むロードマップ形式のプロジェクト
- **タスク**: 日常のルーティンまたは単発のタスク
- **検証モード**:
  - 自己申告（タップ）
  - 写真証拠（長押しでカメラ起動）

### 2. 報酬システム（eギフト統合）
- giftee APIを使用したギフト管理
- ロック済みギフトカード（Glassmorphism）
- 完了時にカードが「砕ける」アニメーションでギフトURLを表示
- タスク完了時に決済（Apple Pay/Stripe）を実行

### 3. 分析・モチベーション
- **アクティビティリング**: Apple Health風の日次完了率表示
- **ヒートマップ**: GitHub風グリッドで毎日のコミットレベルを表示
- **レベルシステム**: タスク完了でXPを獲得し、UIテーマやバッジをアンロック

### 4. ソーシャル機能
- 「承認済みフレンド」のみに制限
- フレンドにロック済みギフトを送信（受信者はタスク完了でアンロック）

## 技術スタック

### クライアント
- **SwiftUI**: モダンなApple UI構築
- **Combine**: リアクティブプログラミング
- **Taptic Engine**: ハプティックフィードバック

### バックエンド（実装予定）
- **Firebase Firestore**: データベース
- **Firebase Authentication**: 認証
- **Firebase Cloud Functions**: サーバーレスロジック
- **giftee API**: ギフト管理
- **Stripe API**: 決済処理

## デザイン

- **Glassmorphism**: 半透明のガラス効果
- **カードレイアウト**: モダンなカードベースUI
- **SF Symbols**: Apple標準アイコン
- **アクティビティリング**: Apple Healthスタイル
- **ヒートマップ**: GitHubスタイル

## セットアップ

### 必要な環境
- Xcode 15.0以上
- iOS 17.0以上をターゲット
- Swift 5.9以上

### インストール手順

#### Xcodeプロジェクトとして開く（推奨）

詳細な手順は [`DOCUMENTATION.md`](DOCUMENTATION.md) を参照してください。

**簡単な手順：**

1. Xcodeを起動
2. `File` > `New` > `Project...` で新規iOS Appプロジェクトを作成
   - プロジェクト名: `GiftyTask`
   - Interface: `SwiftUI`
   - Language: `Swift`
3. 既存のファイル（このプロジェクトの `App/`, `Models/`, `Views/`, `Utilities/`, `ContentView.swift`）をXcodeプロジェクトに追加
4. `App/GiftyTaskApp.swift` がエントリーポイントとして認識されているか確認
5. `⌘R` でビルド＆実行

#### Swift Packageとして使用（ライブラリとして）

1. Xcodeで `File` > `Open Package Dependencies...`
2. このフォルダの `Package.swift` を選択
3. 他のプロジェクトの依存関係として追加

### 設定

1. **カメラ権限**: `Info.plist` に `NSCameraUsageDescription` を追加
2. **Firebase設定**: 後ほど実装
3. **giftee APIキー**: 後ほど実装

## 実装済み機能

### ✅ 完了
- データモデル定義（Task, Epic, Gift, User, ActivityData）
- Glassmorphismモディファイア
- アクティビティリングコンポーネント
- タスクカードコンポーネント（長押しカメラ機能）
- ハプティックマネージャー

### 🔄 実装予定
- Firebase統合
- giftee API統合
- 決済処理（Apple Pay/Stripe）
- 通知システム
- ソーシャル機能
- ヒートマップ表示
- レベルシステム

## サンプルコード

### アクティビティリング

```swift
ActivityRingCardView(
    ringData: ActivityRingData(
        move: 0.8,
        exercise: 0.6,
        stand: 0.9
    ),
    completedTasks: 4,
    goalTasks: 5,
    epicProgress: 0.6,
    activeDays: 18,
    totalDays: 20
)
```

### Glassmorphismタスクカード

```swift
TaskCardView(
    task: Task(
        title: "朝のジョギングを30分",
        description: "健康維持のためのルーティン",
        status: .pending,
        verificationMode: .photoEvidence,
        priority: .high,
        xpReward: 20
    ),
    onComplete: { task, photo in
        // 完了時の処理
    }
)
```

## ライセンス

このプロジェクトは開発用雛形として作成されています。

## 開発者向け情報

セットアップ・アーキテクチャ・トラブルシューティングの詳細は **`DOCUMENTATION.md`** を参照してください。

