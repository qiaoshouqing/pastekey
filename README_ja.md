<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="PasteKey Icon">
</p>

<h1 align="center">PasteKey</h1>

<p align="center">
  カスタムホットキーで定型テキストを即座にペーストできる、軽量な macOS メニューバーアプリです。
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README_zh-Hans.md">简体中文</a> · <a href="README_zh-Hant.md">繁體中文</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue" alt="macOS 13+">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

---

## 特徴

- **即座にペースト** — 任意のアプリでホットキーを押すと、定型テキストが即座にペーストされます
- **カスタムホットキー** — 各スニペットに任意のキーの組み合わせ（例：⌘⇧1）を割り当て
- **クリップボード保護** — ペースト後に元のクリップボード内容を自動復元
- **メニューバーアプリ** — メニューバーに常駐、Dock アイコンなし
- **ログイン時に起動** — オプションの自動起動機能

## インストール

### ソースからビルド

macOS 13+ と Swift 5.9+ が必要です。

```bash
git clone https://github.com/qiaoshouqing/pastekey.git
cd pastekey
swift build -c release
```

ビルド成果物は `.build/release/PasteKey` にあります。

### 直接実行

```bash
swift run PasteKey
```

## 使い方

1. メニューバーのクリップボードアイコンをクリック
2. **Settings...** を選択してメインウィンドウを開く
3. サイドバーからスニペットを選択（または **+** をクリックして新規作成）
4. クイックペーストしたいテキストを入力
5. ホットキー記録ボックスをクリックし、キーの組み合わせを押す（例：⌘⇧1）
6. ウィンドウを閉じる — これで任意のアプリでそのホットキーを押すとテキストがペーストされます

### アクセシビリティ権限

PasteKey はキーボードペーストをシミュレートするためにアクセシビリティ権限が必要です。初回起動時、macOS は **システム設定 > プライバシーとセキュリティ > アクセシビリティ** でアクセスを許可するよう求めます。

## 仕組み

ホットキーを押すと、PasteKey は以下を実行します：

1. 現在のクリップボードを保存
2. スニペットテキストをクリップボードにセット
3. ⌘V をシミュレートしてペースト
4. 元のクリップボードを復元

そのため、ペーストをサポートするほぼすべてのアプリで動作します。

## 技術スタック

- SwiftUI + AppKit
- [HotKey](https://github.com/soffes/HotKey) — グローバルホットキー登録
- Swift Package Manager

## ライセンス

[MIT](LICENSE)
