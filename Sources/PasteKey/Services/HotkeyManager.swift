import Foundation
import HotKey

class HotkeyManager {
    private var activeHotKeys: [UUID: HotKey] = [:]
    private let snippetStore: SnippetStore
    private let pasteService = PasteService()

    init(snippetStore: SnippetStore) {
        self.snippetStore = snippetStore
        rebindAll()

        NotificationCenter.default.addObserver(
            forName: .hotkeyRecordingStarted, object: nil, queue: .main
        ) { [weak self] _ in
            self?.pauseAll()
        }

        NotificationCenter.default.addObserver(
            forName: .hotkeyRecordingStopped, object: nil, queue: .main
        ) { [weak self] _ in
            self?.resumeAll()
        }
    }

    func rebindAll() {
        activeHotKeys.removeAll()

        for snippet in snippetStore.snippets {
            guard snippet.isEnabled, let hotkeyData = snippet.hotkey else { continue }

            let hk = HotKey(keyCombo: hotkeyData.keyCombo)
            let content = snippet.content
            hk.keyDownHandler = { [weak self] in
                self?.pasteService.paste(text: content)
            }
            activeHotKeys[snippet.id] = hk
        }
    }

    private func pauseAll() {
        for hk in activeHotKeys.values {
            hk.isPaused = true
        }
    }

    private func resumeAll() {
        for hk in activeHotKeys.values {
            hk.isPaused = false
        }
    }
}

extension Notification.Name {
    static let hotkeyRecordingStarted = Notification.Name("hotkeyRecordingStarted")
    static let hotkeyRecordingStopped = Notification.Name("hotkeyRecordingStopped")
}
