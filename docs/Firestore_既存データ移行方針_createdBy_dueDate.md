# Firestore 既存データ移行方針（`created_by_*` / `due_date` 補完）

本ドキュメントは、既存の `tasks` / `gifts` データに対して、追加フィールドの欠損を安全に補完するための実運用手順です。

---

## 1. 対象フィールド

### `tasks` コレクション

- `created_by_uid`（string）
- `created_by_name`（string）
- `due_date`（timestamp, 任意）
- `gift_description`（string, 任意）

### `gifts` コレクション

- `created_by_uid`（string）
- `created_by_name`（string）
- `description`（string, 任意, 40文字以内）
- `task_title`（string, 任意）
- `task_due_date`（timestamp, 任意）

---

## 2. 補完ルール（決定版）

### `tasks` の補完

- **`created_by_uid` 欠損時**
  - `sender_id` が存在する場合: `created_by_uid = sender_id`
  - それ以外: 未補完（null のまま）  
    ※ 自分用ローカルタスクは Firestore に存在しない前提

- **`created_by_name` 欠損時**
  - `sender_name` が存在する場合: `created_by_name = sender_name`
  - それ以外: `"ユーザー"`

- **`due_date` 欠損時**
  - 既存データに期限情報が無い場合は **補完しない**（null のまま）
  - UI では「期限なし」として表示

- **`gift_description` 欠損時**
  - 補完しない（null のまま）

### `gifts` の補完

- **`created_by_uid` 欠損時**
  - `associated_task_id` から `tasks/{id}` を参照し、`tasks.created_by_uid` をコピー
  - 取得できない場合は未補完

- **`created_by_name` 欠損時**
  - `associated_task_id` から `tasks.created_by_name` をコピー
  - 取得できない場合は `"ユーザー"`

- **`description` 欠損時**
  - 補完しない（null のまま）
  - 入っている値は 40 文字上限に切り詰める

- **`task_title` / `task_due_date` 欠損時**
  - `associated_task_id` から `tasks.title` / `tasks.due_date` をコピー
  - `due_date` 不在時は `task_due_date` も null のまま

---

## 3. アプリ側フォールバック（すでに実装済み）

既存データに欠損があっても UI が崩れないよう、以下を適用済み:

- タスク作成者表示:
  - `createdByUserName ?? senderName ?? fromDisplayName ?? "自分/匿名ユーザー"`
- ギフト作成者表示:
  - `createdByUserName ?? assignedFromUserName`
- ギフトのタスク名/期限表示:
  - `linkedTaskTitle` / `linkedTaskDueDate` が無ければ `taskId` からローカル `Task` を参照
- 編集可否:
  - `createdByUserId` 優先、旧データは互換フォールバックあり

---

## 4. 段階的移行手順

### Phase 0: 事前準備

- [ ] Firestore Export（バックアップ）を取得
- [ ] ステージング環境で同手順を先行実行
- [ ] サンプリング（100件程度）で補完結果を確認

### Phase 1: 新規書き込みの固定化（完了）

- `sendTask` で新フィールドを書き込む実装をデプロイ済み
- これ以降に作成されるデータは欠損しない

### Phase 2: 既存データ backfill（バッチ）

- Cloud Functions（Admin SDK）または管理スクリプトで実施
- 書き込みは **欠損フィールドのみ**（既存値を上書きしない）
- 1 バッチ 300〜500 write 以内で分割し、再実行可能な idempotent 処理にする

### Phase 3: 検証

- [ ] `tasks` の `created_by_uid` 欠損件数 = 0（または意図した残数）
- [ ] `gifts` の `created_by_uid` 欠損件数 = 0（または参照不能分のみ）
- [ ] 画面上で作成者・期限・詳細が期待通り表示される

---

## 5. バッチ実装の推奨仕様

### 入力

- `tasks` 全件（ページング）
- `gifts` 全件（ページング）

### 処理

1. `tasks` を走査して不足項目を補完
2. `gifts` を走査して `associated_task_id` 経由で不足項目を補完
3. 40文字制限:
   - `description` / `gift_description` は `prefix(40)` 適用

### 重要条件

- `set(..., { merge: true })` 相当で更新
- 既存フィールドが入っている場合は変更しない
- エラー時は doc id をログ出力し、次バッチへ継続

---

## 6. ロールバック方針

- 原則は Firestore Export から復元
- バッチは「欠損フィールドのみ追記」のため、ロールバック不要であることが多い
- 想定外更新時に備え、実行ログ（doc id / 更新フィールド）を保存

---

## 7. 完了条件

- 新規作成分: 欠損なし
- 既存データ: 作成者表示に必要な `created_by_*` が実運用上十分に補完済み
- UI: タスクカード / ギフトカードが最終要件どおりに表示
- 監視: 1週間程度、欠損由来の表示崩れや編集不可不具合が再発しない

