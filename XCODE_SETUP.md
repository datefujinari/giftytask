# Xcodeプロジェクトのセットアップ手順

このプロジェクトをXcodeで開いてビルドするための手順です。

## 方法1: Xcodeで新規プロジェクトを作成（推奨）

### 手順

1. **Xcodeを起動**
   - Xcode 15.0以上を推奨

2. **新規プロジェクトを作成**
   - `File` > `New` > `Project...`
   - `iOS` > `App` を選択
   - プロジェクト名: `GiftyTask`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - 保存場所を選択（既存のプロジェクトフォルダの外に保存）

3. **既存ファイルをインポート**
   - 作成した新規プロジェクトのフォルダ内のファイル（`ContentView.swift`、`GiftyTaskApp.swift`など）を削除
   - このプロジェクトの以下のファイル/フォルダをXcodeプロジェクトにドラッグ&ドロップ：
     - `App/` フォルダ
     - `Models/` フォルダ
     - `Views/` フォルダ
     - `Utilities/` フォルダ
     - `ContentView.swift`
   
   **重要**: 「Copy items if needed」のチェックを外して、既存ファイルへの参照を作成してください

4. **Appエントリーポイントの設定**
   - Xcodeプロジェクトの `App` フォルダ内の `GiftyTaskApp.swift` を確認
   - 既に `@main` 属性が設定されていることを確認

5. **ビルド設定の確認**
   - プロジェクトを選択
   - `General` タブで `iOS Deployment Target` を `17.0` 以上に設定

6. **ビルドと実行**
   - `⌘R` でビルド＆実行
   - iOSシミュレーターまたは実機で動作確認

## 方法2: Swift Packageとして使用（ライブラリとして）

このプロジェクトをSwift Packageとして使用する場合：

1. **XcodeでPackage.swiftを開く**
   ```
   File > Open Package Dependencies...
   このフォルダのPackage.swiftを選択
   ```

2. **依存関係として追加**
   - 他のXcodeプロジェクトで、このSwift Packageを依存関係として追加
   - `File` > `Add Package Dependencies...`
   - ローカルパスまたはGitリポジトリのURLを指定

## トラブルシューティング

### ビルドエラーが発生する場合

1. **ファイルがプロジェクトに追加されていない**
   - プロジェクトナビゲーターで、すべてのファイルが表示されているか確認
   - 表示されていない場合は、再度ドラッグ&ドロップで追加

2. **@main属性のエラー**
   - `App/GiftyTaskApp.swift` が正しく追加されているか確認
   - 他のファイルに `@main` 属性がないか確認（`@main` は1つのファイルにのみ）

3. **型が見つからないエラー**
   - `Models/`、`Views/`、`Utilities/` フォルダが正しく追加されているか確認
   - 各ファイルが正しいターゲットに含まれているか確認

4. **iOS Deployment Targetのエラー**
   - プロジェクト設定で `iOS Deployment Target` を `17.0` 以上に設定

### プレビューが表示されない場合

1. **Canvasを開く**
   - `⌥⌘↩` (Option + Command + Return) でCanvasを開く

2. **プレビューを更新**
   - `⌥⌘P` (Option + Command + P) でプレビューを更新

3. **シミュレーターを選択**
   - Canvas上部のデバイス選択でシミュレーターを選択

## プロジェクト構造

```
GiftyTask/
├── App/
│   └── GiftyTaskApp.swift      # アプリエントリーポイント
├── Models/                      # データモデル
├── Views/                       # SwiftUIビュー
├── Utilities/                   # ユーティリティ
├── ContentView.swift            # メインビュー
└── Package.swift                # Swift Package定義（オプション）
```

## 次のステップ

1. **Firebase統合**（必要に応じて）
   - Firebase SDKを追加
   - `Info.plist` に設定を追加

2. **カメラ権限の設定**
   - `Info.plist` に `NSCameraUsageDescription` を追加

3. **アセットの追加**
   - `Assets.xcassets` に画像やカラーを追加

4. **証明書とプロビジョニングプロファイル**
   - 実機テスト用に設定

