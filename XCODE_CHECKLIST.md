# Xcodeプロジェクト設定チェックリスト

エミュレーターで動作確認する際に、以下の項目を確認してください。

## ✅ 1. ファイルがXcodeプロジェクトに追加されているか

プロジェクトナビゲーターで以下のファイル/フォルダが表示されているか確認：

- [ ] `App/GiftyTaskApp.swift` - アプリエントリーポイント
- [ ] `ContentView.swift` - メインビュー
- [ ] `Models/` フォルダ内のすべてのファイル
  - [ ] `Task.swift`
  - [ ] `Epic.swift`
  - [ ] `Gift.swift`
  - [ ] `User.swift`
  - [ ] `ActivityData.swift`
- [ ] `Views/` フォルダ内のすべてのファイル
  - [ ] `Activity/ActivityRingView.swift`
  - [ ] `Activity/DashboardView.swift`
  - [ ] `Task/TaskCardView.swift`
  - [ ] `Task/TaskListView.swift`
  - [ ] `Gift/GiftCardView.swift`
  - [ ] `Gift/GiftListView.swift`
- [ ] `Utilities/` フォルダ内のすべてのファイル
  - [ ] `GlassmorphismModifier.swift`
  - [ ] `HapticManager.swift`
  - [ ] `PreviewContainer.swift`

## ✅ 2. ファイルがターゲットに含まれているか

各ファイルを選択して、右側のインスペクター（File Inspector）で以下を確認：

- [ ] **Target Membership** で `GiftyTask` にチェックが入っている
- [ ] すべてのSwiftファイルがターゲットに含まれている

**確認方法：**
1. ファイルを選択
2. 右側のインスペクターパネルを開く（⌥⌘1）
3. 「Target Membership」セクションで `GiftyTask` にチェック

## ✅ 3. Appエントリーポイントの確認

- [ ] `App/GiftyTaskApp.swift` に `@main` 属性がある
- [ ] 他のファイルに `@main` 属性がない（1つだけであること）

## ✅ 4. Info.plistの設定

`Info.plist` またはプロジェクト設定で以下を確認：

- [ ] **カメラ権限**: `NSCameraUsageDescription` が設定されている
  - 値: "タスク完了の写真証拠を撮影するためにカメラへのアクセスが必要です"

**設定方法：**
1. プロジェクトを選択
2. `Info` タブを開く
3. `Custom iOS Target Properties` セクションで `+` をクリック
4. `Privacy - Camera Usage Description` を追加
5. 説明文を入力

または、`Info.plist` ファイルに直接追加：
```xml
<key>NSCameraUsageDescription</key>
<string>タスク完了の写真証拠を撮影するためにカメラへのアクセスが必要です</string>
```

## ✅ 5. ビルド設定の確認

- [ ] **iOS Deployment Target**: `17.0` 以上に設定
- [ ] **Swift Language Version**: `Swift 5` 以上
- [ ] **Build Settings** でエラーや警告がない

**確認方法：**
1. プロジェクトを選択
2. `General` タブで `iOS Deployment Target` を確認
3. `Build Settings` タブで `Swift Language Version` を確認

## ✅ 6. ビルドエラーの確認

- [ ] ビルド（⌘B）でエラーがない
- [ ] すべてのインポートが正しく解決されている
- [ ] 型が見つからないエラーがない

**よくあるエラー：**
- `Cannot find type 'Task' in scope` → Modelsフォルダがターゲットに含まれていない
- `Cannot find type 'PreviewContainer' in scope` → Utilitiesフォルダがターゲットに含まれていない
- `@main' attribute used without importing Swift` → App/GiftyTaskApp.swiftがターゲットに含まれていない

## ✅ 7. 実行時の確認

- [ ] エミュレーターでアプリが起動する
- [ ] タブバーが表示される（ダッシュボード、タスク、ギフトBOX）
- [ ] 各タブで画面が表示される
- [ ] プレビュー（⌥⌘↩）が動作する

## 🔧 トラブルシューティング

### ファイルが表示されない場合

1. **ファイルを再追加**
   - プロジェクトナビゲーターで右クリック
   - `Add Files to "GiftyTask"...`
   - ファイル/フォルダを選択
   - **重要**: 「Copy items if needed」のチェックを**外す**
   - 「Create groups」を選択
   - 「Add to targets: GiftyTask」にチェック

### ビルドエラーが発生する場合

1. **クリーンビルド**
   - `Product` > `Clean Build Folder` (⇧⌘K)
   - 再度ビルド（⌘B）

2. **DerivedDataを削除**
   - `Xcode` > `Settings` > `Locations`
   - `Derived Data` のパスを確認
   - Finderでそのフォルダを開き、プロジェクト名のフォルダを削除

3. **ファイルのターゲットメンバーシップを確認**
   - 各ファイルを選択
   - 右側のインスペクターで `GiftyTask` にチェックが入っているか確認

### 機能が動作しない場合

1. **PreviewContainerが正しくインポートされているか確認**
   - `Views/` 内のファイルで `PreviewContainer` を使用している場合、同じターゲットに含まれているか確認

2. **依存関係を確認**
   - すべてのファイルが同じターゲット（`GiftyTask`）に含まれているか確認

## 📝 推奨されるプロジェクト構造（Xcode内）

```
GiftyTask (プロジェクト)
├── GiftyTask (ターゲット)
│   ├── App
│   │   └── GiftyTaskApp.swift
│   ├── ContentView.swift
│   ├── Models
│   │   ├── Task.swift
│   │   ├── Epic.swift
│   │   ├── Gift.swift
│   │   ├── User.swift
│   │   └── ActivityData.swift
│   ├── Views
│   │   ├── Activity
│   │   │   ├── ActivityRingView.swift
│   │   │   └── DashboardView.swift
│   │   ├── Task
│   │   │   ├── TaskCardView.swift
│   │   │   └── TaskListView.swift
│   │   └── Gift
│   │       ├── GiftCardView.swift
│   │       └── GiftListView.swift
│   └── Utilities
│       ├── GlassmorphismModifier.swift
│       ├── HapticManager.swift
│       └── PreviewContainer.swift
└── GiftyTaskTests (テストターゲット)
```

すべてのファイルが `GiftyTask` ターゲットに含まれていることを確認してください。


