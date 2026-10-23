import AppKit
import ApplicationServices

/// 粘贴：先放进剪贴板，授权了辅助功能就替用户按 ⌘V，再把原来的剪贴板还回去
@MainActor
enum PasteService {
    static var canAutoPaste: Bool { AXIsProcessTrusted() }

    static func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    static func copy(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    /// 返回 true 表示已经自动贴进去了；false 表示只放进了剪贴板，需要用户自己 ⌘V
    @discardableResult
    static func paste(_ text: String, autoPaste: Bool, restoreClipboard: Bool) -> Bool {
        let pb = NSPasteboard.general
        guard autoPaste, canAutoPaste else { copy(text); return false }
        let saved = restoreClipboard ? snapshot(pb) : nil
        copy(text)
        let written = pb.changeCount
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let src = CGEventSource(stateID: .combinedSessionState)
            let down = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: true) // V
            let up = CGEvent(keyboardEventSource: src, virtualKey: 9, keyDown: false)
            down?.flags = .maskCommand; up?.flags = .maskCommand
            down?.post(tap: .cghidEventTap); up?.post(tap: .cghidEventTap)
            // 目标 App 读剪贴板需要一点时间；期间用户自己又复制了东西就不还原
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                if let saved, pb.changeCount == written { restore(pb, saved) }
            }
        }
        return true
    }

    private static func snapshot(_ pb: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        (pb.pasteboardItems ?? []).map { item in
            var d: [NSPasteboard.PasteboardType: Data] = [:]
            for t in item.types { if let data = item.data(forType: t) { d[t] = data } }
            return d
        }
    }

    private static func restore(_ pb: NSPasteboard, _ items: [[NSPasteboard.PasteboardType: Data]]) {
        pb.clearContents()
        guard !items.isEmpty else { return }
        pb.writeObjects(items.map { dict in
            let item = NSPasteboardItem()
            for (t, data) in dict { item.setData(data, forType: t) }
            return item
        })
    }
}
