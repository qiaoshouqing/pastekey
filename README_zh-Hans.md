<p align="center"><img src="assets/icon.png" width="128" height="128" alt="PasteKey"></p>

<h1 align="center">PasteKey</h1>

<p align="center"><b>好用的提示词，一个键就贴出去。</b><br>macOS 菜单栏小工具，把你攒的提示词一键贴进 ChatGPT、Claude、Cursor 或任何 App。</p>

<p align="center"><a href="README.md">English</a> · <a href="README_zh-Hant.md">繁體中文</a> · <a href="README_ja.md">日本語</a></p>

---

## 能做什么

- **任何地方按 ⌥ Space**：弹出一个像 Spotlight 的面板，输入几个字搜到提示词，回车，就贴到光标所在的位置。
- **每条提示词可以单独绑快捷键**：最常用的几条设成 ⌃⌥1 这样的组合键，按下直接贴，不用开面板。
- **提示词市场**：内置 24 条精选提示词，分研究、写作、编程、职场、学习、自媒体、翻译 7 类，中英双语，一键添加。目录从这个仓库实时更新，加新提示词不用等 App 发版。
- **变量**：提示词里写 `{{剪贴板}}`、`{{输入}}`、`{{日期}}`、`{{时间}}`。剪贴板和日期自动填好；`{{输入}}` 会在粘贴前让你现填一段。
- **不弄乱剪贴板**：粘贴完，自动把你原来的剪贴板内容还回去。
- **数据在自己手里**：提示词存成本机 JSON 文件，随时导出导入。联网只用来拉取公开的市场目录。

## 安装

在 [Releases](https://github.com/qiaoshouqing/pastekey/releases/latest) 下载 `PasteKey-1.0.0.dmg`，把 PasteKey 拖进「应用程序」。App 用 Developer ID 签名并通过了 Apple 公证，双击就能打开。需要 macOS 13 或更新版本，Apple 芯片和 Intel 都支持。

想要选中后自动粘贴，需要在「系统设置 › 隐私与安全性 › 辅助功能」里打开 PasteKey。不授权也能用：选中后会复制，自己按 ⌘V 即可。

## 投稿提示词

市场目录在 [`catalog/catalog.json`](catalog/catalog.json)。可以直接提 PR 加一条（标题、简介、正文都写 `zh` 和 `en`，再加标签），也可以[开个 issue](https://github.com/qiaoshouqing/pastekey/issues) 把提示词贴给我。改了文件记得把 `version` 加一，已安装的 App 才会更新。

## 从源码构建

```bash
git clone https://github.com/qiaoshouqing/pastekey.git
cd pastekey
open PasteKey.xcodeproj
```

`scripts/release.sh <版本号> [--appstore]` 一条命令完成归档、Developer ID 签名、公证，在 `dist/` 里生成 zip 和 dmg；加 `--appstore` 会同时上传到 App Store Connect。

## 许可

MIT © POMODIARY LLC
