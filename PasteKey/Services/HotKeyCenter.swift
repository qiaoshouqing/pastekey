import Carbon.HIToolbox
import AppKit

/// 管理所有全局快捷键：一个唤出面板的，加上每条提示词各自的。
/// 用 Carbon RegisterEventHotKey，沙盒里可用，注册快捷键本身不需要辅助功能权限。
@MainActor
final class HotKeyCenter {
    static let shared = HotKeyCenter()

    private var refs: [UInt32: EventHotKeyRef] = [:]
    private var actions: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1
    private var handler: EventHandlerRef?
    private(set) var paused = false

    private init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            let id = hk.id
            DispatchQueue.main.async { MainActor.assumeIsolated { HotKeyCenter.shared.fire(id) } }
            return noErr
        }, 1, &spec, nil, &handler)
    }

    private func fire(_ id: UInt32) {
        guard !paused else { return }
        actions[id]?()
    }

    /// 全部重新注册。返回注册失败（被别的 App 占用）的快捷键
    @discardableResult
    func rebind(_ bindings: [(KeyCombo, () -> Void)]) -> [KeyCombo] {
        for ref in refs.values { UnregisterEventHotKey(ref) }
        refs.removeAll(); actions.removeAll(); nextID = 1
        var failed: [KeyCombo] = []
        for (combo, action) in bindings {
            let id = nextID; nextID += 1
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(combo.keyCode, combo.modifiers, EventHotKeyID(signature: OSType(0x504B_4559), id: id),
                                             GetApplicationEventTarget(), 0, &ref)
            if status == noErr, let ref { refs[id] = ref; actions[id] = action } else { failed.append(combo) }
        }
        return failed
    }

    /// 录快捷键时先停掉，免得按下去直接触发
    func pause() { paused = true }
    func resume() { paused = false }
}
