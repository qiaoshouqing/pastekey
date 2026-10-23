import AppKit
import SwiftUI
import Combine
import Carbon.HIToolbox

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let store = PromptStore()
    let market = MarketStore()
    let settings = AppSettings()
    let nav = Navigator()

    private var statusItem: NSStatusItem!
    private var panel: QuickPanel?
    private var panelModel: QuickPanelModel!
    private var keyMonitor: Any?
    private var mainWindow: NSWindow?
    private var bag = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        panelModel = QuickPanelModel(store: store, settings: settings)
        panelModel.onDone = { [weak self] text, paste in self?.deliver(text, paste: paste) }
        panelModel.onOpenApp = { [weak self] section in self?.hidePanel(); self?.showMainWindow(section) }

        setupStatusItem()
        settings.onHotkeysChanged = { [weak self] in self?.rebindHotkeys() }
        store.$prompts
            .map { $0.compactMap { p in p.hotkey.map { ($0, p.id) } }.map { "\($0.0.keyCode)-\($0.0.modifiers)-\($0.1)" } }
            .removeDuplicates()
            .sink { [weak self] _ in self?.rebindHotkeys() }
            .store(in: &bag)

        Task { await market.refresh() }

        #if DEBUG
        // 调试用：-showPanel 启动后直接打开面板；-section prompts|market|settings 打开主窗口
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-section"), i + 1 < args.count, let s = AppSection(rawValue: args[i + 1]) { showMainWindow(s) }
        if args.contains("-showPanel") { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.showPanel() } }
        #endif
        if !settings.onboarded {
            settings.onboarded = true
            showMainWindow(.market)
        }
    }

    // MARK: 快捷键

    private func rebindHotkeys() {
        var bindings: [(KeyCombo, () -> Void)] = []
        if let k = settings.panelHotkey { bindings.append((k, { [weak self] in self?.togglePanel() })) }
        for p in store.prompts { if let k = p.hotkey { let id = p.id; bindings.append((k, { [weak self] in self?.firePrompt(id) })) } }
        let failed = HotKeyCenter.shared.rebind(bindings)
        if !failed.isEmpty { NSLog("PasteKey: hotkeys in use by another app: \(failed.map(\.display))") }
    }

    /// 单条提示词的快捷键：不开面板，直接贴；要现填内容的才弹面板
    private func firePrompt(_ id: UUID) {
        guard let p = store.prompt(id) else { return }
        if p.needsInput {
            showPanel()
            panelModel.beginInput(for: p)
            return
        }
        let text = TemplateRenderer.render(p.body, clipboard: NSPasteboard.general.string(forType: .string), input: nil)
        store.markUsed(id)
        deliver(text, paste: true)
    }

    private func deliver(_ text: String, paste: Bool) {
        hidePanel()
        let pasted = PasteService.paste(text, autoPaste: paste && settings.autoPaste, restoreClipboard: settings.restoreClipboard)
        if !pasted { Toast.show(L.t("已复制，按 ⌘V 粘贴", "Copied — press ⌘V to paste", ja: "コピーしました。⌘V で貼り付け")) }
    }

    // MARK: 面板

    private func togglePanel() { if panel?.isVisible == true { hidePanel() } else { showPanel() } }

    private func showPanel() {
        if panel == nil {
            let host = NSHostingView(rootView: QuickPanelView(model: panelModel, store: store))
            panel = QuickPanel(content: host)
        }
        panelModel.reset()
        guard let panel else { return }
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }) ?? NSScreen.main {
            let f = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: f.midX - panel.frame.width / 2, y: f.minY + f.height * 0.62 - panel.frame.height / 2))
        }
        panel.makeKeyAndOrderFront(nil)
        installKeyMonitor()
    }

    private func hidePanel() {
        panel?.orderOut(nil)
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    private func installKeyMonitor() {
        if keyMonitor != nil { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self, let panel = self.panel, panel.isKeyWindow else { return e }
            let cmd = e.modifierFlags.contains(.command)
            let inInput = self.panelModel.pendingPrompt != nil
            switch Int(e.keyCode) {
            case kVK_Escape:
                if inInput { self.panelModel.pendingPrompt = nil } else { self.hidePanel() }
                return nil
            case kVK_DownArrow where !inInput: self.panelModel.move(1); return nil
            case kVK_UpArrow where !inInput: self.panelModel.move(-1); return nil
            case kVK_Return, kVK_ANSI_KeypadEnter:
                if inInput {
                    guard cmd else { return e } // 普通回车留给输入框换行
                    self.panelModel.confirmInput(paste: true)
                } else {
                    self.panelModel.choose(paste: !cmd)
                }
                return nil
            default: return e
            }
        }
    }

    // MARK: 主窗口

    func showMainWindow(_ section: AppSection? = nil) {
        if let section { nav.section = section }
        if mainWindow == nil {
            let root = MainView()
                .environmentObject(store).environmentObject(market).environmentObject(settings).environmentObject(nav)
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 980, height: 640),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                             backing: .buffered, defer: false)
            w.title = "PasteKey"
            w.contentView = NSHostingView(rootView: root)
            w.isReleasedWhenClosed = false
            w.setFrameAutosaveName("PasteKeyMain")
            w.center()
            mainWindow = w
        }
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: 菜单栏

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "text.badge.star", accessibilityDescription: "PasteKey")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let open = NSMenuItem(title: L.t("搜索提示词…", "Search prompts…", ja: "プロンプトを検索…") + (settings.panelHotkey.map { "   \($0.display)" } ?? ""),
                              action: #selector(openPanelFromMenu), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        menu.addItem(.separator())

        let quick = store.sorted.prefix(8)
        if !quick.isEmpty {
            let header = NSMenuItem(title: L.t("常用", "Frequent", ja: "よく使う"), action: nil, keyEquivalent: ""); header.isEnabled = false
            menu.addItem(header)
            for p in quick {
                let item = NSMenuItem(title: p.title + (p.hotkey.map { "   \($0.display)" } ?? ""), action: #selector(copyFromMenu(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = p.id
                item.toolTip = L.t("点击复制", "Click to copy", ja: "クリックでコピー")
                menu.addItem(item)
            }
            menu.addItem(.separator())
        }
        for (title, section) in [(L.t("管理提示词…", "Manage prompts…", ja: "プロンプトを管理…"), AppSection.prompts), (L.t("提示词市场…", "Prompt market…", ja: "プロンプトマーケット…"), AppSection.market), (L.t("设置…", "Settings…", ja: "設定…"), AppSection.settings)] {
            let item = NSMenuItem(title: title, action: #selector(openSection(_:)), keyEquivalent: section == .settings ? "," : "")
            item.target = self; item.representedObject = section.rawValue
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: L.t("退出 PasteKey", "Quit PasteKey", ja: "PasteKey を終了"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    @objc private func openPanelFromMenu() { showPanel() }

    @objc private func copyFromMenu(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID, let p = store.prompt(id) else { return }
        if p.needsInput { showPanel(); panelModel.beginInput(for: p); return }
        PasteService.copy(TemplateRenderer.render(p.body, clipboard: NSPasteboard.general.string(forType: .string), input: nil))
        store.markUsed(id)
        Toast.show(L.t("已复制「\(p.title)」", "Copied “\(p.title)”", ja: "「\(p.title)」をコピーしました"))
    }

    @objc private func openSection(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let s = AppSection(rawValue: raw) else { return }
        showMainWindow(s)
    }
}
