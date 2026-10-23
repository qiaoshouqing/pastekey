<p align="center"><img src="assets/icon.png" width="128" height="128" alt="PasteKey"></p>

<h1 align="center">PasteKey</h1>

<p align="center"><b>Your AI prompts, one keystroke away.</b><br>A macOS menu bar app that pastes your best prompts into ChatGPT, Claude, Cursor or any other app.</p>

<p align="center"><a href="README_zh-Hans.md">简体中文</a> · <a href="README_zh-Hant.md">繁體中文</a> · <a href="README_ja.md">日本語</a></p>

---

## What it does

- **⌥ Space anywhere** — a Spotlight-style panel opens over any app. Type to search your prompts, press ↩, and the prompt is pasted where your cursor was.
- **A hotkey per prompt** — give your most-used prompts their own shortcut (e.g. ⌃⌥1). Press it and the text is pasted instantly, no panel.
- **Prompt market** — 24 hand-picked prompts for research, writing, coding, work, learning, social media and translation, in English and Chinese. Add any of them with one click. The catalog updates from this repo, so new prompts arrive without an app update.
- **Variables** — write `{{clipboard}}`, `{{input}}`, `{{date}}` or `{{time}}` in a prompt. Clipboard and date are filled in automatically; `{{input}}` asks you for text before pasting.
- **Clipboard-safe** — after pasting, your previous clipboard is restored.
- **Private** — prompts are stored on your Mac as plain JSON. Export and import them any time. The network is only used to fetch the public market catalog.

## Install

Download `PasteKey-1.0.0.dmg` from the [latest release](https://github.com/qiaoshouqing/pastekey/releases/latest) and drag PasteKey to Applications. The app is signed with Developer ID and notarized by Apple. Requires macOS 13 or later, Apple Silicon or Intel.

To paste automatically, allow PasteKey under **System Settings › Privacy & Security › Accessibility**. Without that permission PasteKey still works: the prompt is copied and you press ⌘V.

## Contribute a prompt

The market lives in [`catalog/catalog.json`](catalog/catalog.json). Open a pull request with a new entry (title, summary and body in `zh` and `en`, plus tags), or [open an issue](https://github.com/qiaoshouqing/pastekey/issues) with your prompt. Bump `version` when you change the file so installed apps pick it up.

## Build from source

```bash
git clone https://github.com/qiaoshouqing/pastekey.git
cd pastekey
open PasteKey.xcodeproj
```

`scripts/release.sh <version> [--appstore]` archives, signs with Developer ID, notarizes, and writes a zip and dmg to `dist/`. With `--appstore` it also uploads the build to App Store Connect.

## License

MIT © POMODIARY LLC
