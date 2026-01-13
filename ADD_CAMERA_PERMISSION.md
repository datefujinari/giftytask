# カメラ権限の追加方法

## 方法1: Infoタブで追加（推奨）

1. **`+` ボタンをクリック**
   - Infoタブの「Custom iOS Target Properties」セクションの左下にある `+` ボタンをクリック

2. **キー名を入力**
   - 検索ボックスに `NSCameraUsageDescription` と入力
   - または、一覧から `Privacy - Camera Usage Description` を探す
   - 見つからない場合は、直接 `NSCameraUsageDescription` と入力してEnter

3. **値を設定**
   - Type: `String`
   - Value: `タスク完了の写真証拠を撮影するためにカメラへのアクセスが必要です`

## 方法2: Info.plistファイルを直接編集

1. **Info.plistファイルを開く**
   - プロジェクトナビゲーターで `Info.plist` を探す
   - 見つからない場合は、プロジェクトを選択 → `Info` タブ → 右クリック → `Open As` > `Source Code`

2. **以下のXMLを追加**
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>タスク完了の写真証拠を撮影するためにカメラへのアクセスが必要です</string>
   ```

## 方法3: 検索で見つける

Infoタブの `+` ボタンをクリックした後：

1. 検索ボックスに `camera` と入力
2. 候補から `Privacy - Camera Usage Description` を選択
3. 値に説明文を入力

## 確認方法

追加後、Infoタブの「Custom iOS Target Properties」に以下が表示されていればOK：
- Key: `Privacy - Camera Usage Description` または `NSCameraUsageDescription`
- Type: `String`
- Value: `タスク完了の写真証拠を撮影するためにカメラへのアクセスが必要です`


