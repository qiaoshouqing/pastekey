<p align="center">
  <img src="assets/icon.png" width="128" height="128" alt="PasteKey Icon">
</p>

<h1 align="center">PasteKey</h1>

<p align="center">
  一个轻量级的 macOS 菜单栏应用，让你通过自定义快捷键即时粘贴预设文本片段。
</p>

<p align="center">
  <a href="README.md">English</a> · <a href="README_zh-Hant.md">繁體中文</a> · <a href="README_ja.md">日本語</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue" alt="macOS 13+">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="MIT License">
</p>

---

## 功能特性

- **即时粘贴** — 在任意应用中按下快捷键，预设文本立即粘贴
- **自定义快捷键** — 为每个片段分配任意组合键（如 ⌘⇧1）
- **剪贴板安全** — 粘贴后自动恢复原有剪贴板内容
- **菜单栏应用** — 安静地驻留在菜单栏，无 Dock 图标
- **开机自启** — 可选的登录时自动启动

## 安装

### 从源码构建

需要 macOS 13+ 和 Swift 5.9+。

```bash
git clone https://github.com/qiaoshouqing/pastekey.git
cd pastekey
swift build -c release
```

构建产物位于 `.build/release/PasteKey`。

### 直接运行

```bash
swift run PasteKey
```

## 使用方法

1. 点击菜单栏中的剪贴板图标
2. 选择 **Settings...** 打开主窗口
3. 从左侧边栏选择一个片段（或点击 **+** 新建）
4. 输入你想要快速粘贴的文本
5. 点击快捷键录制框，按下组合键（如 ⌘⇧1）
6. 关闭窗口 — 现在在任意应用中按下该快捷键即可粘贴文本

### 辅助功能权限

PasteKey 需要辅助功能权限来模拟键盘粘贴操作。首次启动时，macOS 会提示你在 **系统设置 > 隐私与安全性 > 辅助功能** 中授予权限。

## 工作原理

当你按下快捷键时，PasteKey 会：

1. 保存当前剪贴板内容
2. 将片段文本写入剪贴板
3. 模拟 ⌘V 进行粘贴
4. 恢复原有的剪贴板内容

因此它几乎可以在所有支持粘贴的应用中工作。

## 技术栈

- SwiftUI + AppKit
- [HotKey](https://github.com/soffes/HotKey) 用于全局快捷键注册
- Swift Package Manager

## 许可证

[MIT](LICENSE)
