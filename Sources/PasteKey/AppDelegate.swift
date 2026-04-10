import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let snippetStore = SnippetStore()
    var statusBarController: StatusBarController?
    var hotkeyManager: HotkeyManager?
    private var cancellables = Set<AnyCancellable>()
    private var mainWindow: NSWindow?
    private var mainWindowDelegate: MainWindowDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AccessibilityChecker.checkAndPrompt()

        statusBarController = StatusBarController(
            snippetStore: snippetStore,
            onOpenSettings: { [weak self] in self?.showMainWindow() }
        )
        hotkeyManager = HotkeyManager(snippetStore: snippetStore)

        snippetStore.objectWillChange
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.hotkeyManager?.rebindAll()
                    self?.statusBarController?.rebuildMenu()
                }
            }
            .store(in: &cancellables)
    }

    func showMainWindow() {
        if mainWindow == nil {
            let contentView = MainView()
                .environmentObject(snippetStore)

            let delegate = MainWindowDelegate()
            self.mainWindowDelegate = delegate

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 460),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "PasteKey"
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.setFrameAutosaveName("PasteKeyMain")
            window.minSize = NSSize(width: 560, height: 400)
            window.isReleasedWhenClosed = false
            window.delegate = delegate
            mainWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
        mainWindow?.orderFrontRegardless()
    }
}

private class MainWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
