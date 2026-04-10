import SwiftUI
import AppKit
import Carbon

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var keyComboData: KeyComboData?
    var onRecord: () -> Void

    func makeNSView(context: Context) -> HotkeyRecorderNSView {
        let view = HotkeyRecorderNSView()
        view.onKeyComboRecorded = { combo in
            keyComboData = combo
            onRecord()
        }
        view.onClear = {
            keyComboData = nil
            onRecord()
        }
        view.displayedCombo = keyComboData
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderNSView, context: Context) {
        nsView.displayedCombo = keyComboData
        nsView.onKeyComboRecorded = { combo in
            keyComboData = combo
            onRecord()
        }
        nsView.onClear = {
            keyComboData = nil
            onRecord()
        }
        nsView.needsDisplay = true
    }
}

class HotkeyRecorderNSView: NSView {
    var displayedCombo: KeyComboData?
    var onKeyComboRecorded: ((KeyComboData) -> Void)?
    var onClear: (() -> Void)?
    private(set) var isRecording = false
    private var localMonitor: Any?
    private var trackingArea: NSTrackingArea?
    private var isHovered = false

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let bgColor: NSColor
        if isRecording {
            bgColor = .controlAccentColor.withAlphaComponent(0.15)
        } else if isHovered {
            bgColor = .controlBackgroundColor.withSystemEffect(.pressed)
        } else {
            bgColor = .controlBackgroundColor
        }
        bgColor.setFill()

        let path = NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6)
        path.fill()

        let borderColor: NSColor = isRecording ? .controlAccentColor : .separatorColor
        borderColor.setStroke()
        path.lineWidth = isRecording ? 1.5 : 1.0
        path.stroke()

        let text: String
        if isRecording {
            text = "Type shortcut..."
        } else if let combo = displayedCombo {
            text = combo.displayString
        } else {
            text = "Click to record"
        }

        let textColor: NSColor
        if isRecording {
            textColor = .controlAccentColor
        } else if displayedCombo != nil {
            textColor = .labelColor
        } else {
            textColor = .secondaryLabelColor
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: displayedCombo != nil ? .medium : .regular),
            .foregroundColor: textColor
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let size = attrStr.size()
        let textRect = CGRect(
            x: 8,
            y: (bounds.height - size.height) / 2,
            width: bounds.width - 16,
            height: size.height
        )
        attrStr.draw(in: textRect)
    }

    override func mouseDown(with event: NSEvent) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        handleKeyEvent(event)
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }
    }

    private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
        needsDisplay = true

        NotificationCenter.default.post(name: .hotkeyRecordingStarted, object: nil)

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isRecording else { return event }
            self.handleKeyEvent(event)
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        needsDisplay = true

        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        NotificationCenter.default.post(name: .hotkeyRecordingStopped, object: nil)
    }

    private func handleKeyEvent(_ event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            stopRecording()
            return
        }

        if event.keyCode == UInt16(kVK_Delete) {
            onClear?()
            stopRecording()
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasModifier = modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option)

        guard hasModifier else { return }

        var carbonMods: UInt32 = 0
        if modifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
        if modifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbonMods |= UInt32(controlKey) }
        if modifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }

        let combo = KeyComboData(
            carbonKeyCode: UInt32(event.keyCode),
            carbonModifiers: carbonMods
        )
        onKeyComboRecorded?(combo)
        stopRecording()
    }
}
