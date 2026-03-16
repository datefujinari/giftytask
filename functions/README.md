# GiftyTask Cloud Functions

タスク完了・承認に伴い、Firestore の `tasks` 更新をトリガーに FCM プッシュを送信します。

## 機能

- **タスクが pending_approval になったとき**  
  送信者（sender_id）の `users/{uid}.fcm_token` 宛に  
  「〇〇さんがタスクを完了しました！承認してください」を送信。  
  （〇〇は受信者の display_name）

- **タスクが completed になったとき**  
  受信者（receiver_id）の `users/{uid}.fcm_token` 宛に  
  「おめでとう！タスクが承認され、ギフトが解禁されました！」を送信。

## デプロイ手順

1. Firebase CLI をインストール（未導入の場合）  
   `npm install -g firebase-tools`

2. ログイン  
   `firebase login`

3. プロジェクトを紐付け（初回のみ）  
   `firebase use <your-project-id>`

4. 依存関係インストール  
   `cd functions && npm install`

5. デプロイ  
   `firebase deploy --only functions`

## 必要な Firestore 構造

- `tasks`: `sender_id`, `receiver_id`, `status`（"pending_approval" / "completed"）
- `users`: `fcm_token`, `display_name`（受信者名表示用）

## 注意

- 各ユーザーの `fcm_token` が Firestore の `users` に保存されている必要があります（アプリ側でログイン時に保存）。
- APNs 認証キー（.p8）を Firebase Console のプロジェクト設定に登録済みである必要があります。
