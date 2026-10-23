import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var store: PromptStore
    @EnvironmentObject var market: MarketStore
    @State private var trusted = PasteService.canAutoPaste
    @State private var loginItem = LoginItem.isEnabled
    @State private var message: String?
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section(L.t("快捷键", "Shortcut", ja: "ショートカット")) {
                HStack {
                    Text(L.t("唤出提示词面板", "Open the prompt panel", ja: "プロンプトパネルを開く"))
                    Spacer()
                    HotkeyRecorder(combo: Binding(get: { settings.panelHotkey }, set: { settings.panelHotkey = $0 })).frame(width: 170, height: 26)
                }
                Text(L.t("每条提示词也可以单独绑快捷键，在「我的提示词」里设置。", "Each prompt can also have its own hotkey under My Prompts.", ja: "プロンプトごとのショートカットは「マイプロンプト」で設定できます。"))
                    .font(.callout).foregroundStyle(.secondary)
            }
            Section(L.t("粘贴", "Pasting", ja: "貼り付け")) {
                Toggle(L.t("选中后直接粘贴到当前 App", "Paste into the current app", ja: "選んだら今のアプリにそのまま貼り付ける"), isOn: $settings.autoPaste)
                Toggle(L.t("粘贴后恢复原来的剪贴板", "Restore your clipboard after pasting", ja: "貼り付け後に元のクリップボードを戻す"), isOn: $settings.restoreClipboard)
                HStack(alignment: .top) {
                    Image(systemName: trusted ? "checkmark.circle.fill" : "exclamationmark.circle").foregroundStyle(trusted ? .green : .orange)
                    Text(trusted ? L.t("已授权辅助功能，可以自动粘贴。", "Accessibility is granted.", ja: "アクセシビリティが許可されています。")
                                 : L.t("自动粘贴需要在「系统设置 › 隐私与安全性 › 辅助功能」里打开 PasteKey。不授权也能用：选中后会复制，你自己按 ⌘V。", "To paste automatically, allow PasteKey under System Settings › Privacy & Security › Accessibility. Without it, prompts are copied and you press ⌘V.", ja: "自動で貼り付けるには、「システム設定 › プライバシーとセキュリティ › アクセシビリティ」で PasteKey を許可してください。許可しなくても使えます。その場合はコピーされるので ⌘V で貼り付けます。"))
                        .font(.callout)
                    Spacer()
                    if !trusted { Button(L.t("去授权", "Grant", ja: "許可する")) { PasteService.requestAccessibility() } }
                }
            }
            Section(L.t("通用", "General", ja: "一般")) {
                Toggle(L.t("开机自动启动", "Launch at login", ja: "ログイン時に起動"), isOn: $loginItem).onChange(of: loginItem) { LoginItem.set($0) }
            }
            Section(L.t("提示词", "Prompts", ja: "プロンプト")) {
                HStack {
                    Button(L.t("导出我的提示词…", "Export my prompts…", ja: "プロンプトを書き出す…")) { exportPrompts() }
                    Button(L.t("导入…", "Import…", ja: "読み込む…")) { importPrompts() }
                    Spacer()
                    Text(L.t("共 \(store.prompts.count) 条", "\(store.prompts.count) prompts", ja: "全 \(store.prompts.count) 件")).foregroundStyle(.secondary)
                }
                HStack {
                    Text(L.t("市场目录 v\(market.catalog.version) · \(market.catalog.prompts.count) 条", "Market v\(market.catalog.version) · \(market.catalog.prompts.count) prompts", ja: "マーケット v\(market.catalog.version) · \(market.catalog.prompts.count) 件")).foregroundStyle(.secondary)
                    Spacer()
                    Button(L.t("检查更新", "Check for updates", ja: "更新を確認")) { Task { await market.refresh() } }
                }
                if let message { Text(message).font(.callout).foregroundStyle(.secondary) }
            }
            Section(L.t("关于", "About", ja: "このアプリについて")) {
                HStack {
                    Text("PasteKey \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                    Spacer()
                    Link(L.t("投稿提示词 / 反馈", "Submit a prompt / Feedback", ja: "プロンプトを投稿 / フィードバック"), destination: URL(string: "https://github.com/qiaoshouqing/pastekey/issues")!)
                }
                Text(L.t("你的提示词只存在这台 Mac 上，不会上传。联网只用来更新提示词市场的目录。", "Your prompts stay on this Mac. The network is only used to update the market catalog.", ja: "プロンプトはこの Mac の中だけに保存されます。通信はマーケットの目録更新にのみ使います。"))
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(L.t("设置", "Settings", ja: "設定"))
        .onReceive(timer) { _ in trusted = PasteService.canAutoPaste }
    }

    private func exportPrompts() {
        guard let data = store.exportData() else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "PasteKey-prompts.json"
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url)
            message = L.t("已导出到 \(url.lastPathComponent)", "Exported to \(url.lastPathComponent)", ja: "\(url.lastPathComponent) に書き出しました")
        }
    }

    private func importPrompts() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) {
            let n = store.importData(data)
            message = L.t("导入了 \(n) 条新提示词", "Imported \(n) new prompts", ja: "新しいプロンプトを \(n) 件読み込みました")
        }
    }
}
