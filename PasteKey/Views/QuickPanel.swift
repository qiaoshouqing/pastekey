import AppKit
import SwiftUI

/// 像 Spotlight 一样的浮动面板：不抢前台 App 的焦点，选完直接贴回去
final class QuickPanel: NSPanel {
    init(content: NSView) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 680, height: 440),
                   styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                   backing: .buffered, defer: false)
        isFloatingPanel = true
        level = .floating
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        for b in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] { standardWindowButton(b)?.isHidden = true }
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        contentView = content
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class QuickPanelModel: ObservableObject {
    @Published var query = "" { didSet { selection = 0 } }
    @Published var selection = 0
    @Published var pendingPrompt: Prompt?
    @Published var inputText = ""

    let store: PromptStore
    let settings: AppSettings
    /// 选好以后：文字、是否粘贴
    var onDone: ((String, Bool) -> Void)?
    var onOpenApp: ((AppSection) -> Void)?

    init(store: PromptStore, settings: AppSettings) { self.store = store; self.settings = settings }

    var items: [Prompt] { store.search(query) }

    func reset() { query = ""; selection = 0; pendingPrompt = nil; inputText = "" }

    func move(_ delta: Int) {
        let n = items.count
        guard n > 0 else { return }
        selection = (selection + delta + n) % n
    }

    func choose(_ prompt: Prompt? = nil, paste: Bool) {
        let list = items
        guard let p = prompt ?? (list.indices.contains(selection) ? list[selection] : nil) else { return }
        if p.needsInput { pendingPrompt = p; inputText = ""; return }
        finish(p, input: nil, paste: paste)
    }

    /// 单条快捷键触发、但需要现填内容时，直接进入填写页
    func beginInput(for p: Prompt) { pendingPrompt = p; inputText = "" }

    func confirmInput(paste: Bool) {
        guard let p = pendingPrompt else { return }
        finish(p, input: inputText, paste: paste)
    }

    private func finish(_ p: Prompt, input: String?, paste: Bool) {
        let text = TemplateRenderer.render(p.body, clipboard: NSPasteboard.general.string(forType: .string), input: input)
        store.markUsed(p.id)
        onDone?(text, paste)
    }
}

struct QuickPanelView: View {
    @ObservedObject var model: QuickPanelModel
    @ObservedObject var store: PromptStore
    @FocusState private var searchFocused: Bool
    @FocusState private var inputFocused: Bool

    var body: some View {
        Group {
            if let p = model.pendingPrompt { inputView(p) } else { listView }
        }
        .frame(width: 680, height: 440)
        .background(VisualEffect(material: .hudWindow).ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.primary.opacity(0.08)))
    }

    private var listView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.system(size: 17))
                TextField(L.t("搜索提示词", "Search prompts"), text: $model.query)
                    .textFieldStyle(.plain).font(.system(size: 20)).focused($searchFocused)
                    .onSubmit { model.choose(paste: true) }
            }
            .padding(.horizontal, 18).padding(.vertical, 15)
            Divider()
            let items = model.items
            if items.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "text.quote").font(.system(size: 30)).foregroundStyle(.tertiary)
                    Text(L.t("没有找到提示词", "No prompts found")).foregroundStyle(.secondary)
                    Button(L.t("去提示词市场挑几个", "Browse the prompt market")) { model.onOpenApp?(.market) }.buttonStyle(.link)
                    Spacer()
                }.frame(maxWidth: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { i, p in
                                QuickRow(prompt: p, selected: i == model.selection)
                                    .id(i)
                                    .onTapGesture { model.selection = i; model.choose(p, paste: true) }
                            }
                        }.padding(8)
                    }
                    .onChange(of: model.selection) { i in proxy.scrollTo(i, anchor: .center) }
                }
            }
            Divider()
            HStack(spacing: 14) {
                Hint(keys: "↩", text: model.settings.autoPaste ? L.t("粘贴", "Paste") : L.t("复制", "Copy"))
                Hint(keys: "⌘↩", text: L.t("只复制", "Copy only"))
                Hint(keys: "↑↓", text: L.t("选择", "Select"))
                Hint(keys: "esc", text: L.t("关闭", "Close"))
                Spacer()
                Button { model.onOpenApp?(.prompts) } label: { Label(L.t("管理提示词", "Manage"), systemImage: "square.grid.2x2") }
                    .buttonStyle(.plain).foregroundStyle(.secondary).font(.caption)
            }
            .padding(.horizontal, 16).padding(.vertical, 9)
        }
        .onAppear { searchFocused = true }
    }

    private func inputView(_ p: Prompt) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { model.pendingPrompt = nil } label: { Image(systemName: "chevron.left") }.buttonStyle(.plain)
                Text(p.title).font(.headline)
                Spacer()
            }
            Text(L.t("这条提示词里有「{{输入}}」，先填上要放进去的内容：", "This prompt has an {{input}} slot. Fill it in:"))
                .font(.callout).foregroundStyle(.secondary)
            TextEditor(text: $model.inputText)
                .font(.system(size: 15)).focused($inputFocused)
                .scrollContentBackground(.hidden)
                .padding(8).background(Color.primary.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 8))
            HStack {
                Text(L.t("⌘↩ 粘贴   esc 返回", "⌘↩ paste   esc back")).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(L.t("只复制", "Copy")) { model.confirmInput(paste: false) }
                Button(L.t("粘贴", "Paste")) { model.confirmInput(paste: true) }.buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .onAppear { inputFocused = true }
    }
}

private struct Hint: View {
    let keys: String; let text: String
    var body: some View {
        HStack(spacing: 4) {
            Text(keys).font(.system(size: 11, weight: .medium, design: .rounded))
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(Color.primary.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 4))
            Text(text).font(.caption)
        }.foregroundStyle(.secondary)
    }
}

private struct QuickRow: View {
    let prompt: Prompt; let selected: Bool
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: prompt.needsInput ? "text.cursor" : "text.quote").frame(width: 22).foregroundStyle(selected ? .white : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(prompt.title).font(.system(size: 14, weight: .medium)).lineLimit(1)
                Text(prompt.body.replacingOccurrences(of: "\n", with: " ")).font(.system(size: 12)).lineLimit(1).opacity(0.7)
            }
            Spacer()
            if let k = prompt.hotkey {
                Text(k.display).font(.system(size: 11, weight: .medium, design: .rounded))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background((selected ? Color.white : Color.primary).opacity(0.15)).clipShape(RoundedRectangle(cornerRadius: 4))
            }
            if prompt.favorite { Image(systemName: "star.fill").font(.caption).foregroundStyle(selected ? .white : .yellow) }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .foregroundStyle(selected ? .white : .primary)
        .background(selected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(Rectangle())
    }
}

struct VisualEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView(); v.material = material; v.blendingMode = .behindWindow; v.state = .active; return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

/// 没自动粘贴时提示「已复制」
@MainActor
enum Toast {
    private static var window: NSWindow?
    static func show(_ text: String) {
        let host = NSHostingView(rootView:
            Text(text).font(.system(size: 14, weight: .medium)).padding(.horizontal, 18).padding(.vertical, 10)
                .background(VisualEffect(material: .hudWindow)).clipShape(Capsule()))
        let size = host.fittingSize
        host.frame = NSRect(origin: .zero, size: size)
        let w = window ?? NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false; w.backgroundColor = .clear; w.level = .statusBar; w.ignoresMouseEvents = true; w.hasShadow = false
        w.contentView = host
        w.setContentSize(size)
        if let f = NSScreen.main?.visibleFrame { w.setFrameOrigin(NSPoint(x: f.midX - size.width / 2, y: f.minY + 120)) }
        w.alphaValue = 1; w.orderFrontRegardless(); window = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            NSAnimationContext.runAnimationGroup { $0.duration = 0.3; w.animator().alphaValue = 0 }
        }
    }
}
