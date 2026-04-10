<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="PasteKey Icon">
</p>

<h1 align="center">PasteKey</h1>

<p align="center">
  一個輕量級的 macOS 選單列應用程式，讓你透過自訂快捷鍵即時貼上預設文字片段。
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README_zh-Hans.md">简体中文</a> · <a href="README_ja.md">日本語</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue" alt="macOS 13+">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

---

## 功能特色

- **即時貼上** — 在任意應用程式中按下快捷鍵，預設文字立即貼上
- **自訂快捷鍵** — 為每個片段指定任意組合鍵（如 ⌘⇧1）
- **剪貼簿安全** — 貼上後自動恢復原有剪貼簿內容
- **選單列應用** — 安靜地駐留在選單列，無 Dock 圖示
- **登入時啟動** — 可選的登入時自動啟動

## 安裝

### 從原始碼建構

需要 macOS 13+ 和 Swift 5.9+。

```bash
git clone https://github.com/qiaoshouqing/pastekey.git
cd pastekey
swift build -c release
```

建構產物位於 `.build/release/PasteKey`。

### 直接執行

```bash
swift run PasteKey
```

## 使用方法

1. 點擊選單列中的剪貼簿圖示
2. 選擇 **Settings...** 開啟主視窗
3. 從左側邊欄選擇一個片段（或點擊 **+** 新增）
4. 輸入你想要快速貼上的文字
5. 點擊快捷鍵錄製框，按下組合鍵（如 ⌘⇧1）
6. 關閉視窗 — 現在在任意應用程式中按下該快捷鍵即可貼上文字

### 輔助使用權限

PasteKey 需要輔助使用權限來模擬鍵盤貼上操作。首次啟動時，macOS 會提示你在 **系統設定 > 隱私權與安全性 > 輔助使用** 中授予權限。

## 運作原理

當你按下快捷鍵時，PasteKey 會：

1. 儲存目前剪貼簿內容
2. 將片段文字寫入剪貼簿
3. 模擬 ⌘V 進行貼上
4. 恢復原有的剪貼簿內容

因此它幾乎可以在所有支援貼上的應用程式中運作。

## 技術棧

- SwiftUI + AppKit
- [HotKey](https://github.com/soffes/HotKey) 用於全域快捷鍵註冊
- Swift Package Manager

## 授權條款

[MIT](LICENSE)
