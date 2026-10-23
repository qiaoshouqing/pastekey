import SwiftUI

struct PromptsView: View {
    @EnvironmentObject var store: PromptStore
    @EnvironmentObject var nav: Navigator
    @State private var query = ""

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                HStack {
                    TextField(L.t("搜索", "Search"), text: $query).textFieldStyle(.roundedBorder)
                    Button { newPrompt() } label: { Image(systemName: "plus") }.help(L.t("新建提示词", "New prompt"))
                }.padding(10)
                List(selection: $nav.selectedPromptID) {
                    ForEach(store.search(query)) { p in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                if p.favorite { Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption) }
                                Text(p.title).font(.system(size: 13, weight: .medium)).lineLimit(1)
                                Spacer()
                                if let k = p.hotkey {
                                    Text(k.display).font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .padding(.horizontal, 5).padding(.vertical, 1)
                                        .background(Color.primary.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 3))
                                }
                            }
                            Text(p.body.replacingOccurrences(of: "\n", with: " ")).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }
                        .padding(.vertical, 3).tag(p.id)
                        .contextMenu {
                            Button(p.favorite ? L.t("取消收藏", "Unfavorite") : L.t("收藏", "Favorite")) { store.toggleFavorite(p.id) }
                            Button(L.t("复制", "Copy")) { PasteService.copy(p.body) }
                            Divider()
                            Button(L.t("删除", "Delete"), role: .destructive) { store.delete(p.id) }
                        }
                    }
                }
            }
            .frame(minWidth: 260, idealWidth: 300, maxWidth: 380)

            Group {
                if let id = nav.selectedPromptID, let p = store.prompt(id) {
                    PromptEditor(prompt: p).id(p.id)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "keyboard").font(.system(size: 38)).foregroundStyle(.tertiary)
                        Text(L.t("选一条提示词来编辑，或者新建一条", "Pick a prompt to edit, or create one")).foregroundStyle(.secondary)
                        HStack {
                            Button(L.t("新建提示词", "New prompt")) { newPrompt() }
                            Button(L.t("逛逛提示词市场", "Browse the market")) { nav.section = .market }
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 440)
        }
        .navigationTitle(L.t("我的提示词", "My Prompts"))
        .onAppear { if nav.selectedPromptID == nil { nav.selectedPromptID = store.sorted.first?.id } }
    }

    private func newPrompt() {
        let p = Prompt(title: L.t("新提示词", "New prompt"), body: "")
        store.upsert(p)
        nav.selectedPromptID = p.id
    }
}

struct PromptEditor: View {
    @EnvironmentObject var store: PromptStore
    @State var prompt: Prompt
    @State private var tagsText = ""
    @State private var copied = false
    @State private var conflict: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                TextField(L.t("标题", "Title"), text: $prompt.title).textFieldStyle(.plain).font(.system(size: 20, weight: .semibold))
                Spacer()
                Button { prompt.favorite.toggle() } label: { Image(systemName: prompt.favorite ? "star.fill" : "star") }
                    .buttonStyle(.plain).foregroundStyle(prompt.favorite ? .yellow : .secondary).help(L.t("收藏", "Favorite"))
            }
            HStack(spacing: 10) {
                Label(L.t("快捷键", "Hotkey"), systemImage: "keyboard").font(.callout).foregroundStyle(.secondary)
                HotkeyRecorder(combo: Binding(get: { prompt.hotkey }, set: setHotkey))
                    .frame(width: 170, height: 26)
                if prompt.hotkey != nil {
                    Button { prompt.hotkey = nil } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain)
                }
                Text(conflict ?? L.t("按下就直接贴出这条，不用打开面板", "Pastes this prompt directly")).font(.caption)
                    .foregroundStyle(conflict == nil ? Color.secondary : Color.orange)
            }
            HStack {
                TextField(L.t("分类", "Category"), text: $prompt.category).textFieldStyle(.roundedBorder).frame(width: 160)
                TextField(L.t("标签，用逗号分开", "Tags, comma separated"), text: $tagsText).textFieldStyle(.roundedBorder)
            }
            ZStack(alignment: .topLeading) {
                TextEditor(text: $prompt.body)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .padding(10)
                if prompt.body.isEmpty {
                    Text(L.t("在这里写提示词。可以用 {{剪贴板}}、{{输入}} 这样的变量，粘贴时自动替换。", "Write your prompt. Variables like {{clipboard}} and {{input}} are filled in when pasting."))
                        .foregroundStyle(.tertiary).padding(15).allowsHitTesting(false)
                }
            }
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            HStack(spacing: 6) {
                Text(L.t("插入变量：", "Insert:")).font(.caption).foregroundStyle(.secondary)
                ForEach(TemplateVariable.allCases, id: \.self) { v in
                    Button(v.label) { prompt.body += v.insertToken }.controlSize(.small)
                }
                Spacer()
                if prompt.useCount > 0 { Text(L.t("用过 \(prompt.useCount) 次", "Used \(prompt.useCount)×")).font(.caption).foregroundStyle(.secondary) }
            }
            HStack {
                Button(L.t("删除", "Delete"), role: .destructive) { store.delete(prompt.id) }
                Spacer()
                Button(copied ? L.t("已复制", "Copied") : L.t("复制", "Copy")) {
                    PasteService.copy(TemplateRenderer.render(prompt.body, clipboard: NSPasteboard.general.string(forType: .string), input: nil))
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
                }
            }
        }
        .padding(20)
        .onAppear { tagsText = prompt.tags.joined(separator: ", ") }
        .onChange(of: prompt) { store.upsert($0) }
        .onChange(of: tagsText) { t in
            prompt.tags = t.split(whereSeparator: { $0 == "," || $0 == "，" }).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
    }

    private func setHotkey(_ combo: KeyCombo?) {
        conflict = nil
        if let combo, let other = store.owner(of: combo, except: prompt.id) {
            conflict = L.t("「\(other.title)」已经在用 \(combo.display)", "\(combo.display) is used by “\(other.title)”")
            return
        }
        prompt.hotkey = combo
    }
}
