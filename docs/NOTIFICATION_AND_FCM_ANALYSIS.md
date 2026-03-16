# ログ分析：通知・FCM まわりの問題点

## 1. 致命的：APNs エンタイトルメント未設定（プッシュ通知が動かない原因）

```
FCM: APNs registration failed: アプリケーションの有効な"aps-environment"エンタイトルメント文字列が見つかりません
```

**意味**  
アプリに **Push Notifications  capability（aps-environment エンタイトルメント）** が付いていません。

**結果**
- APNs（Apple Push Notification service）に登録できない
- デバイストークンが取得できない
- そのため FCM トークンも取得できない（下記ログの直接の原因）

**対処（必須）**
1. Xcode でプロジェクトを開く
2. ターゲット **GiftyTask** を選択 → **Signing & Capabilities**
3. **+ Capability** から **Push Notifications** を追加
4. （必要なら）同じ画面で **Background Modes** を追加し、**Remote notifications** にチェック

これを行わない限り、リモートプッシュ（FCM）は動きません。  
**ローカル通知（テスト通知ボタンなど）は、この設定がなくても動作します。**

---

## 2. FCM トークン取得失敗（1 の結果）

```
[FirebaseMessaging][I-FCM002022] APNS device token not set before retrieving FCM Token for Sender ID '...'
[FirebaseMessaging][I-FCM002022] Declining request for FCM Token since no APNS Token specified
refreshFCMTokenIfNeeded error: The operation couldn't be completed. No APNS token specified before fetching FCM Token
```

**意味**  
FCM は「APNs のデバイストークン」がないと FCM トークンを発行しません。  
上記 1 で APNs 登録が失敗しているため、FCM トークンも取れていません。

**対処**  
**1 の Push Notifications を有効にすれば解消**します。  
実機でビルドし、正しくプロビジョニングされていれば、起動後に APNs トークン → FCM トークンが順に設定されます。

---

## 3. ネットワークエラー（環境依存）

```
nw_endpoint_flow_failed_with_error [C 1 ... 2404:6800:4002:824::200a.443 failed ... (No network route)]
nw_connection_get_connected_socket_block_invoke [C 1 ] Client called nw_connection_get_connected_socket on unconnected nw_connection
TCP Conn 0x... Failed : error 0 : 50 [ 50 ]
```

**意味**  
- IPv6 の宛先（Google など）へのルートがない  
- または接続前にソケット取得を呼んでいる  

**想定原因**
- シミュレータのネット設定
- 開発環境のファイアウォール / VPN
- 実機の機内モード・Wi‑Fi 不調

**対処**  
実機 + 通常の Wi‑Fi/ cellular で試すと消えることが多いです。  
FCM の動作には「1 の修正」の方が重要です。

---

## 4. Firebase Messaging の Method Swizzling について

ログ冒頭の「set it to NO」と  
https://firebase.google.com/docs/cloud-messaging/ios/client#method_swizzling_in_firebase_messaging  
の案内は、**Method Swizzling を無効にしている場合の手動統合**用です。

**現状**
- Swizzling を特にオフにしていなければ、**まず 1 の Push Notifications 追加だけでよい**です。
- 手動で APNs トークンを FCM に渡す実装にしている場合だけ、上記ドキュメントの「Swizzling 無効時の手順」に従ってください。

---

## 5. ログのバグ（修正済み）

```
[NotificationService] authorizationStatus = \(settings.authorizationStatus.rawValue)
```

**意味**  
文字列補間の typo で、数値ではなくリテラル `\(settings.authorizationStatus.rawValue)` が出力されていました。

**対処**  
`NotificationService.swift` の print を  
`print("[NotificationService] authorizationStatus = \(settings.authorizationStatus.rawValue)")`  
に修正済みです。  
再実行すると `0`（未設定）/ `1`（拒否）/ `2`（許可）などが正しく出ます。

---

## まとめ（やる順）

| 優先度 | 内容 | やること |
|--------|------|----------|
| 高 | プッシュが動かない | Xcode で **Signing & Capabilities** に **Push Notifications** を追加する |
| 高 | FCM トークンが取れない | 上記と同じ（APNs が通れば FCM も取得される） |
| 低 | ネットエラー | 実機・通常ネットで再試行。必要なら環境を見直す |
| 済 | 通知許可ログ | `NotificationService` の print を修正済み |

**ローカル通知だけ試したい場合**  
Push Notifications を付けなくても、「テスト通知を送る」のようなローカル通知は、  
通知許可をユーザーが「許可」していれば動作します。  
その場合、上記 5 の修正で「許可状態」がログで正しく確認できます。
