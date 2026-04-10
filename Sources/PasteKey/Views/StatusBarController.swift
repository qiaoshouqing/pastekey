import AppKit
import ServiceManagement

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private let snippetStore: SnippetStore
    private let onOpenSettings: () -> Void

    init(snippetStore: SnippetStore, onOpenSettings: @escaping () -> Void) {
        self.snippetStore = snippetStore
        self.onOpenSettings = onOpenSettings
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "PasteKey")
        }

        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        for snippet in snippetStore.snippets {
            guard snippet.isEnabled, !snippet.name.isEmpty else { continue }
            let hotkeyStr = snippet.hotkey?.displayString ?? ""
            let title = hotkeyStr.isEmpty ? snippet.name : "\(snippet.name)  \(hotkeyStr)"
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        if menu.items.count > 0 {
            menu.addItem(NSMenuItem.separator())
        }

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit PasteKey", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {}
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
