# GiftyTask 開発ドキュメント

本ドキュメントは、プロジェクトのセットアップ・アーキテクチャ・トラブルシューティングをまとめた統合ガイドです。

---

## 1. プロジェクト概要

「努力を価値に変える」をコンセプトにした、ゲーミフィケーションとeギフトを融合させたiOS向けタスク管理アプリ。

### 主要機能
- **タスク管理**: Epic（大目標）とタスク、検証モード（自己申告/写真証拠）
- **報酬システム**: ギフト管理、ロック済みカード、アンロックアニメーション
- **分析**: アクティビティリング、GitHub風ヒートマップ、レベル・XP
- **ソーシャル**: フレンドへのギフト送信

### 技術スタック
- SwiftUI / Combine / Taptic Engine
- UserDefaults（ローカル永続化）
- Firebase（Auth / Firestore）

---

## 2. Firebase コンソールの確認（Auth/Firestore 連携時）

実機で「データが保存されない・取得できない」場合は以下を確認してください。

### 2.1 Authentication：匿名認証の有効化（必須）

- **場所**: Firebaseコンソール > 構築 > Authentication > Sign-in method
- **確認**: 「匿名 (Anonymous)」を **有効** にする
- **理由**: 無効だと `signInAnonymously()` がエラーになり、UID が発行されずタスクの sender_id が空になってセキュリティルールで弾かれる

### 2.2 Firestore：データ型（日付）

Swift の `Date` と Firestore の `Timestamp` を扱う場合は、FirebaseFirestoreSwift の `@ServerTimestamp` などを検討する。現状の tasks/gifts は日付フィールドを [String: Any] で書き込んでいるため、必要に応じて追加する。

### 2.3 Firestore：複合インデックス

「receiver_id が自分」かつ「createdAt 順」など複合条件でクエリする場合、複合インデックスが必要。  
アプリ実行時にコンソールに表示される `https://console.firebase.google.com/...` のURLを開くと、必要なインデックス作成画面に遷移できる。

### 2.4 Firestore：セキュリティルール例

「自分の関わるタスクだけ」に絞る例:

```javascript
match /tasks/{taskId} {
  allow read, write: if request.auth != null &&
    (request.auth.uid == resource.data.sender_id || request.auth.uid == request.resource.data.sender_id ||
     request.auth.uid == resource.data.receiver_id || request.auth.uid == request.resource.data.receiver_id);
}
match /gifts/{giftId} {
  allow read, write: if request.auth != null;
}
```

---

## 3. アーキテクチャ

```
GiftyTask/
├── App/
│   └── GiftyTaskApp.swift
├── Models/          # Task, Epic, Gift, User, ActivityData
├── Views/           # SwiftUIビュー（Activity, Task, Gift, Epic など）
├── ViewModels/      # TaskViewModel, GiftViewModel, ActivityViewModel, EpicViewModel
├── Utilities/       # GlassmorphismModifier, HapticManager, PreviewContainer
└── Resources/       # Assets, Info.plist
```

データフロー: タスク完了 → ViewModel更新 → UserDefaults保存 → UI更新

---

## 4. セットアップ

### 3.1 Xcodeでプロジェクトを開く

1. `GiftyTask/GiftyTask.xcodeproj` を開く
2. 必要な環境: Xcode 15.0以上、iOS 17.0以上、Swift 5.9以上

### 3.2 ファイルをXcodeに追加する

プロジェクトナビゲーターにファイルが反映されない場合:

1. 「GiftyTask」フォルダを右クリック → 「Add Files to "GiftyTask"...」
2. Models / Views / Utilities フォルダを選択
3. **「Copy items if needed」のチェックを外す**
4. 「Create groups」を選択
5. 「Add to targets: GiftyTask」にチェック

### 3.3 カメラ権限

Info.plist またはプロジェクトの Info タブで追加:

- Key: `Privacy - Camera Usage Description`（または `NSCameraUsageDescription`）
- Value: `タスク完了の写真証拠を撮影するためにカメラへのアクセスが必要です`

---

## 5. 実機で動作確認する手順

1. **プロジェクトを開く**: `GiftyTask/GiftyTask.xcodeproj`
2. **iPhoneをUSB接続**し、デバイス選択で実機を選択
3. **署名設定（初回）**: Signing & Capabilities で Team を選択、Bundle ID をユニークに
4. **Run（⌘R）** で実行
5. 初回は「未信頼のデベロッパ」と出る場合あり → 設定 → 一般 → VPNとデバイス管理 で信頼

### トラブルシューティング

| 現象 | 対処 |
|------|------|
| ビルドできない | Product → Clean Build Folder（⇧⌘K）後、再度 Run |
| 実機が一覧に出ない | ケーブル接続確認、Xcode再起動 |
| 署名エラー | Team 選択、Bundle ID 変更 |
| 触覚が鳴らない | 実機の設定でシステム触覚をON（シミュレータでは非対応） |

---

## 6. プロジェクトチェックリスト

### ファイル・ターゲット確認
- [ ] App/GiftyTaskApp.swift、ContentView.swift が1つずつ
- [ ] Models / Views / Utilities 内の全ファイルがプロジェクトに含まれている
- [ ] 各ファイルの Target Membership で `GiftyTask` にチェック

### ビルド設定
- [ ] iOS Deployment Target: 17.0以上
- [ ] Info.plist にカメラ権限あり

---

## 7. トラブルシューティング

### 重複ファイルエラー（"Multiple commands produce" / "Filename used twice"）

1. プロジェクトナビゲーターで重複参照を確認
2. 重複しているファイル参照を選択 → Delete → 「Remove Reference」（Move to Trash は選択しない）
3. Product → Clean Build Folder（⇧⌘K）
4. DerivedData 内の `GiftyTask-*` フォルダを削除して再ビルド

### ビルドエラー: DEVELOPMENT_ASSET_PATHS

- Build Settings で `DEVELOPMENT_ASSET_PATHS` を検索し削除または空にする
- または `App/Preview Content` フォルダを正しいパスに作成

### ビルドエラー: No such module 'XCTest'

- テストターゲットの General で Host Application が GiftyTask か確認
- Build Phases の Link Binary With Libraries に XCTest.framework を追加

### ファイル参照が赤くなる（パス不一致）

- 赤いフォルダを削除（Remove Reference）
- 正しいパスから Add Files で再追加（Copy items if needed は外す）

---

## 8. 画面一覧（概要）

- **認証**: WelcomeView, SignInView, OnboardingView
- **メイン**: HomeView（タブルート）, TaskListView, TaskDetailView, TaskCardView
- **エピック**: EpicListView, EpicDetailView
- **ギフト**: GiftListView, GiftCardView, GiftUnlockView
- **アクティビティ**: ActivityView, ActivityRingView, GiftyHeatmapView, StatisticsView
- **ソーシャル**: FriendListView, GiftAssignmentView
- **設定**: SettingsView（自分のUID表示・タップでコピー。他者にタスクを送る際の相手UID入力に利用）, ProfileView

---

## 9. ヒートマップ機能

GitHub風ヒートマップ（GiftyHeatmapView）の仕様:

- **5段階表示**: タスク完了数に応じて 0〜4 のレベルで色分け
- **カスタマイズ**: ColorPicker でベースカラー変更（UserDefaults に永続化）
- **データ**: ActivityViewModel の `heatmapData` と連携

---

## 10. 参考

- プロジェクトルートの `README.md` にサンプルコードやライセンス情報あり
