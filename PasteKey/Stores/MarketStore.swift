import Foundation

/// 提示词市场：App 里自带一份目录，启动后再去 GitHub 拉最新版。
/// 以后加新提示词，只改仓库里的 catalog/catalog.json，不用发新版本。
@MainActor
final class MarketStore: ObservableObject {
    static let remoteURL = URL(string: "https://raw.githubusercontent.com/qiaoshouqing/pastekey/main/catalog/catalog.json")!
    private let cacheFile = "catalog-cache.json"

    @Published private(set) var catalog: MarketCatalog
    @Published private(set) var isRefreshing = false
    @Published private(set) var lastError: String?

    init() {
        let bundled = MarketStore.bundledCatalog()
        let cached = JSONFile.load(MarketCatalog.self, from: cacheFile)
        // 取版本号更新的那份
        if let c = cached, c.version >= (bundled?.version ?? 0) { catalog = c }
        else { catalog = bundled ?? MarketCatalog(version: 0, updatedAt: "", categories: [], prompts: []) }
    }

    static func bundledCatalog() -> MarketCatalog? {
        guard let url = Bundle.main.url(forResource: "catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(MarketCatalog.self, from: data)
    }

    func categoryName(_ id: String) -> String {
        catalog.categories.first { $0.id == id }?.name.value ?? id
    }

    func prompts(in category: String?, query: String) -> [MarketPrompt] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return catalog.prompts.filter { p in
            (category == nil || p.category == category)
                && (q.isEmpty || p.title.value.lowercased().contains(q) || p.summary.value.lowercased().contains(q)
                    || p.body.value.lowercased().contains(q) || p.tags.all.contains { $0.lowercased().contains(q) })
        }
        .sorted { ($0.featured ?? false ? 1 : 0) > ($1.featured ?? false ? 1 : 0) }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            var request = URLRequest(url: Self.remoteURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
            request.setValue("PasteKey", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
            let remote = try JSONDecoder().decode(MarketCatalog.self, from: data)
            if remote.version >= catalog.version {
                catalog = remote
                JSONFile.save(remote, to: cacheFile)
            }
            lastError = nil
        } catch {
            lastError = L.t("暂时连不上市场，先显示本地的提示词", "Couldn't reach the market. Showing the built-in prompts.", ja: "マーケットに接続できません。内蔵のプロンプトを表示しています。")
        }
    }
}
