# Firebase に APNs 認証キー（.p8）を登録する手順

FCM から iOS 端末へリモートプッシュを送るには、Firebase が Apple に「このアプリのプッシュ送信」として認証する必要があります。そのために **APNs 認証キー（.p8）** を Apple Developer で作成し、Firebase Console に登録します。

---

## 前提

- Apple Developer アカウントがあること
- Firebase プロジェクトに iOS アプリ（GiftyTask）が追加済みであること
- FCM トークンが端末で取得でき、Firestore の `users/{uid}` に `fcm_token` が保存されていること（済み）

---

## ステップ 1：Apple Developer で APNs キー（.p8）を作成する

1. **Apple Developer** にログイン  
   https://developer.apple.com/account/

2. 左メニューで **「Certificates, Identifiers & Profiles」** → **「Keys」** を開く。

3. **「+」**（キーを追加）をクリック。

4. **Key Name** に任意の名前を入力（例：`GiftyTask APNs Key`）。

5. **Apple Push Notifications service (APNs)** にチェックを入れる。

6. **「This service must have environment and type configured」** と表示された場合は、**「Configure」** をクリックする。  
   - 開いた設定で **Environment**（Development / Production、または両方）と **Type** を選択し、保存する。  
   - これで **Continue** が押せるようになる。

7. **Continue** → **Register** でキーを作成。

8. **Download** をクリックして **.p8 ファイル**をダウンロード。  
   - **重要**：このファイルは **1回しかダウンロードできません**。  
   - 安全な場所に保存し、**Key ID** と **Team ID**・**Bundle ID** をメモする（次の画面に表示されます）。

9. ダウンロード完了画面で次を控える：
   - **Key ID**（例：`ABC123XYZ0`）
   - （すでに分かっていれば）**Team ID**・**Bundle ID**（GiftyTask の Bundle ID：`com.date.GiftyTask`）

10. **Done** をクリック。

---

## ステップ 2：Firebase Console に APNs 認証キーを登録する

1. **Firebase Console** を開く  
   https://console.firebase.google.com/

2. 対象の **プロジェクト**（GiftyTask を追加したプロジェクト）を選択。

3. 左上の **歯車アイコン** → **「プロジェクトの設定」**（Project settings）を開く。

4. 下にスクロールし、**「クラウドメッセージング」**（Cloud Messaging）セクションを探す。

5. その中に **「Apple アプリ設定」**（Apple app configuration）がある。  
   - iOS アプリが複数ある場合は、**GiftyTask**（Bundle ID: `com.date.GiftyTask`）の行を選ぶ。

6. **「APNs 認証キー」**（APNs Authentication Key）の **「アップロード」**（Upload）をクリック。

7. 次の内容を入力・選択する：

   | 項目 | 入力内容 |
   |------|----------|
   | **APNs 認証キー** | ステップ 1 でダウンロードした **.p8 ファイル** を選択 |
   | **キー ID** | ステップ 1 で控えた **Key ID** を入力 |
   | **Apple チーム ID** | Apple Developer の **Team ID**（Account → Membership で確認可能） |
   | **Apple Bundle ID** | `com.date.GiftyTask`（GiftyTask の Bundle ID） |

8. **「アップロード」** をクリックして保存。

9. 成功すると、同じ画面に「APNs 認証キーが設定されました」のように表示されます。

---

## ステップ 3：動作確認の考え方

- **Firebase Console から「テストメッセージ」を送る**  
  Firebase Console の **「Cloud Messaging」**（旧「通知」）で「最初のキャンペーン」や「テストメッセージ」を作成し、**FCM トークン**（Firestore の `users/{uid}` の `fcm_token` の値）を指定して送信すると、その端末にプッシュが届きます。

- **Cloud Functions や FCM API から送る**  
  - Cloud Functions なら、トリガー（例：Firestore の `tasks` 作成時）で `admin.messaging().send()` などを使い、`token: 相手の fcm_token` を指定して送信します。  
  - サーバーや別アプリから送る場合は、FCM HTTP v1 API で同じように `token` に `fcm_token` を指定します。

---

## よくある注意点

- **.p8 は 1 回しかダウンロードできない**  
  紛失した場合は、Apple Developer で新しいキーを作成し、再度 Firebase にアップロードする必要があります。

- **Team ID の確認方法**  
  Apple Developer → **Account** → **Membership details** の **Team ID**。  
  または Xcode の **Signing & Capabilities** で「Team」を選んだときのチーム名の横に表示されます。

- **開発（development）と本番（production）**  
  .p8 キーは開発・本番の両方で使えます。Firebase に 1 つ登録すれば、Debug/Release どちらのビルドにも送れます。

---

## まとめチェックリスト

- [ ] Apple Developer の **Keys** で **APNs** 用キーを作成し、**.p8** をダウンロード
- [ ] **Key ID** をメモ
- [ ] Firebase Console → **プロジェクトの設定** → **クラウドメッセージング** → **Apple アプリ設定**
- [ ] **APNs 認証キー** に .p8 をアップロードし、Key ID・Team ID・Bundle ID を入力して保存
- [ ] （任意）Firebase Console の Cloud Messaging でテストメッセージを送り、実機で受信できるか確認

ここまで完了すると、FCM 経由で GiftyTask の実機にリモートプッシュを送れる状態になります。
