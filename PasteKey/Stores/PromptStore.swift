import Foundation

@MainActor
final class PromptStore: ObservableObject {
    @Published private(set) var prompts: [Prompt] = []
    private let file = "prompts.json"

    init() {
        if let saved = JSONFile.load([Prompt].self, from: file) {
            prompts = saved
        } else {
            prompts = PromptStore.migrateFromV1() + PromptStore.starterPrompts()
            persist()
        }
    }

    /// 收藏在前，其次最近用过，最后按创建时间
    var sorted: [Prompt] {
        prompts.sorted { a, b in
            if a.favorite != b.favorite { return a.favorite }
            switch (a.lastUsedAt, b.lastUsedAt) {
            case let (x?, y?): return x > y
            case (_?, nil): return true
            case (nil, _?): return false
            default: return a.createdAt > b.createdAt
            }
        }
    }

    var withHotkeys: [Prompt] { prompts.filter { $0.hotkey != nil } }

    func search(_ query: String) -> [Prompt] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sorted }
        return sorted.filter { p in
            p.title.lowercased().contains(q) || p.body.lowercased().contains(q)
                || p.tags.contains { $0.lowercased().contains(q) } || p.category.lowercased().contains(q)
        }
    }

    func prompt(_ id: UUID) -> Prompt? { prompts.first { $0.id == id } }

    func upsert(_ prompt: Prompt) {
        var p = prompt
        p.updatedAt = Date()
        if let i = prompts.firstIndex(where: { $0.id == p.id }) {
            guard prompts[i] != p else { return }
            prompts[i] = p
        } else { prompts.insert(p, at: 0) }
        persist()
    }

    func delete(_ id: UUID) { prompts.removeAll { $0.id == id }; persist() }

    func toggleFavorite(_ id: UUID) {
        guard let i = prompts.firstIndex(where: { $0.id == id }) else { return }
        prompts[i].favorite.toggle(); persist()
    }

    func markUsed(_ id: UUID) {
        guard let i = prompts.firstIndex(where: { $0.id == id }) else { return }
        prompts[i].useCount += 1
        prompts[i].lastUsedAt = Date()
        persist()
    }

    /// 同一组快捷键只能给一条用；返回占用它的那条
    func owner(of combo: KeyCombo, except id: UUID?) -> Prompt? {
        prompts.first { $0.hotkey == combo && $0.id != id }
    }

    func contains(marketID: String) -> Bool { prompts.contains { $0.marketID == marketID } }

    @discardableResult
    func add(from market: MarketPrompt, categoryName: String) -> Prompt {
        if let existing = prompts.first(where: { $0.marketID == market.id }) { return existing }
        let p = Prompt(title: market.title.value, body: market.body.value, category: categoryName,
                       tags: market.tags.value, marketID: market.id)
        prompts.insert(p, at: 0)
        persist()
        return p
    }

    // MARK: 导入导出（JSON，换电脑或分享给朋友）
    func exportData() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // 快捷键因人而异，导出时去掉
        return try? encoder.encode(prompts.map { var p = $0; p.hotkey = nil; return p })
    }

    func importData(_ data: Data) -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let incoming = try? decoder.decode([Prompt].self, from: data) else { return 0 }
        var added = 0
        for var p in incoming where !prompts.contains(where: { $0.title == p.title && $0.body == p.body }) {
            p.id = UUID(); p.hotkey = nil
            prompts.append(p)
            added += 1
        }
        persist()
        return added
    }

    private func persist() { JSONFile.save(prompts, to: file) }

    /// 0.1 版把片段存在 UserDefaults 里，第一次打开新版时搬过来
    private static func migrateFromV1() -> [Prompt] {
        struct OldCombo: Codable { var carbonKeyCode: UInt32; var carbonModifiers: UInt32 }
        struct OldSnippet: Codable { var id: UUID; var name: String; var content: String; var hotkey: OldCombo?; var isEnabled: Bool }
        guard let data = UserDefaults.standard.data(forKey: "com.pastekey.snippets"),
              let old = try? JSONDecoder().decode([OldSnippet].self, from: data) else { return [] }
        return old.filter { !$0.content.isEmpty }.map { s in
            Prompt(id: s.id, title: s.name.isEmpty ? L.t("未命名", "Untitled") : s.name, body: s.content,
                   hotkey: s.isEnabled ? s.hotkey.map { KeyCombo(keyCode: $0.carbonKeyCode, modifiers: $0.carbonModifiers) } : nil)
        }
    }

    /// 第一次打开放进去三条，马上就能试
    static func starterPrompts() -> [Prompt] {
        guard let catalog = MarketStore.bundledCatalog() else { return [] }
        return ["deeper", "explain-like-expert", "polish-writing"].compactMap { id in
            guard let m = catalog.prompts.first(where: { $0.id == id }) else { return nil }
            let cat = catalog.categories.first { $0.id == m.category }?.name.value ?? ""
            return Prompt(title: m.title.value, body: m.body.value, category: cat, tags: m.tags.value,
                          favorite: id == "deeper", marketID: m.id)
        }
    }
}
