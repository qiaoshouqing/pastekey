import SwiftUI
import AppKit
import Carbon.HIToolbox

/// 点一下开始录，按下组合键就记下；Esc 取消，Delete 清除
struct HotkeyRecorder: NSViewRepresentable {
    @Binding var combo: KeyCombo?
    var placeholder: String = L.t("点击录制快捷键", "Click to record")

    func makeNSView(context: Context) -> RecorderView {
        let v = RecorderView()
        v.placeholder = placeholder
        v.onChange = { combo = $0 }
        v.combo = combo
        return v
    }

    func updateNSView(_ v: RecorderView, context: Context) {
        v.combo = combo
        v.onChange = { combo = $0 }
        v.needsDisplay = true
    }

    final class RecorderView: NSView {
        var combo: KeyCombo?
        var placeholder = ""
        var onChange: ((KeyCombo?) -> Void)?
        private var recording = false
        private var monitor: Any?

        override var acceptsFirstResponder: Bool { true }
        override var intrinsicContentSize: NSSize { NSSize(width: 170, height: 26) }

        override func draw(_ dirtyRect: NSRect) {
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
            (recording ? NSColor.controlAccentColor.withAlphaComponent(0.12) : NSColor.controlBackgroundColor).setFill()
            path.fill()
            (recording ? NSColor.controlAccentColor : NSColor.separatorColor).setStroke()
            path.lineWidth = recording ? 1.5 : 1
            path.stroke()
            let text = recording ? L.t("请按下组合键…", "Press keys…") : (combo?.display ?? placeholder)
            let color: NSColor = recording ? .controlAccentColor : (combo == nil ? .secondaryLabelColor : .labelColor)
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 12, weight: combo == nil ? .regular : .semibold), .foregroundColor: color]
            let s = NSAttributedString(string: text, attributes: attrs)
            let size = s.size()
            s.draw(at: NSPoint(x: (bounds.width - size.width) / 2, y: (bounds.height - size.height) / 2))
        }

        override func mouseDown(with event: NSEvent) { recording ? stop() : start() }

        private func start() {
            recording = true
            window?.makeFirstResponder(self)
            Task { @MainActor in HotKeyCenter.shared.pause() }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
                guard let self, self.recording else { return e }
                self.handle(e); return nil
            }
            needsDisplay = true
        }

        private func stop() {
            recording = false
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            Task { @MainActor in HotKeyCenter.shared.resume() }
            needsDisplay = true
        }

        private func handle(_ e: NSEvent) {
            if e.keyCode == UInt16(kVK_Escape) { stop(); return }
            if e.keyCode == UInt16(kVK_Delete) || e.keyCode == UInt16(kVK_ForwardDelete) { onChange?(nil); stop(); return }
            let f = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard f.contains(.command) || f.contains(.control) || f.contains(.option) else { NSSound.beep(); return }
            var m: UInt32 = 0
            if f.contains(.command) { m |= UInt32(cmdKey) }
            if f.contains(.option) { m |= UInt32(optionKey) }
            if f.contains(.control) { m |= UInt32(controlKey) }
            if f.contains(.shift) { m |= UInt32(shiftKey) }
            onChange?(KeyCombo(keyCode: UInt32(e.keyCode), modifiers: m))
            stop()
        }
    }
}
