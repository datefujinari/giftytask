# Cloud Functions と FCM プッシュ（バックグラウンド・終了時）

アプリがバックグラウンドまたは終了しているときも、Firestore の変更をトリガーに **FCM 経由で通知**します。  
（フォアグラウンドでは Firestore リスナー側のローカル通知と二重にならないよう、`gifty_cf` 付きプッシュはバナー非表示）

## 送信タイミング（`functions/index.js`）

| トリガー | 通知先 | 内容 |
|----------|--------|------|
| `tasks` 新規作成（`status == pending`） | `receiver_id` | 新着タスク |
| `tasks` 削除 | `receiver_id` | タスク取り消し |
| `tasks` 更新で `pending_approval` に遷移 | `sender_id` | 完了報告 |
| `tasks` 更新で `completed` に遷移 | `receiver_id` | 承認・ギフト解放 |
| `routine_suggestions` 新規（`status == pending`） | `receiver_id` | ルーティン提案 |

## 前提条件

1. **Blaze プラン**（従量課金）  
   Cloud Functions のデプロイ・実行に必要です。

2. **Firebase Console → Cloud Messaging**  
   - iOS: **APNs 認証キー（.p8）** を登録済みであること  
   - Xcode で **Push Notifications** 能力を有効にしていること  

3. **各ユーザーの `users/{uid}.fcm_token`**  
   アプリ起動・通知許可後に `AuthManager.saveFCMToken` で保存されます。未保存だと Functions ログに `no fcm_token` と出て送信されません。

4. **Google Cloud API**  
   プロジェクトで **Firebase Cloud Messaging API** が有効であること（多くの場合 Firebase 連携で有効）。

## デプロイ手順

```bash
cd /path/to/taskapp
firebase login
firebase use <あなたのプロジェクトID>
firebase deploy --only functions
```

初回のみ依存関係:

```bash
cd functions && npm install && cd ..
```

## リージョン

既定は **`us-central1`** です。日本向けに寄せる場合は `functions/index.js` 内の `region: "us-central1"` を **`asia-northeast1`** などに統一して変更し、再デプロイしてください。

## ログ確認

Firebase Console → **Functions** → 関数を選択 → **ログ**  
または:

```bash
firebase functions:log
```

送信失敗時は無効トークン・APNs 設定ミスなどがログに出ます。

## 今後の拡張例

- **ギフト受け取りを作成者へ通知**: `gifts` の更新トリガーで `assigned_from_user_id` 等に送信（データ設計の確認が必要）
- **ルーティン提案の削除・承諾**: `onDocumentDeleted` / `onDocumentUpdated` を `routine_suggestions` に追加

## iOS 側の挙動

- **バックグラウンド / 終了**: システムが通知を表示（サウンドは `default`）。
- **フォアグラウンド**: `gifty_cf == 1` のリモート通知はバナーを出さず、既存のローカル通知のみ表示。
