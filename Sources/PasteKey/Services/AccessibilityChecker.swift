import AppKit

enum AccessibilityChecker {
    static func checkAndPrompt() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }
}
