import Foundation
import SwiftUI

@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("autoPaste") var autoPaste: Bool = true
    @AppStorage("restoreClipboard") var restoreClipboard: Bool = true
    @AppStorage("panelHotkey") private var panelHotkeyData: Data = (try? JSONEncoder().encode(KeyCombo.defaultPanel)) ?? Data()
    @AppStorage("onboarded") var onboarded: Bool = false

    var panelHotkey: KeyCombo? {
        get { try? JSONDecoder().decode(KeyCombo.self, from: panelHotkeyData) }
        set {
            objectWillChange.send()
            panelHotkeyData = (try? JSONEncoder().encode(newValue)) ?? Data()
            onHotkeysChanged?()
        }
    }

    var onHotkeysChanged: (() -> Void)?
}
