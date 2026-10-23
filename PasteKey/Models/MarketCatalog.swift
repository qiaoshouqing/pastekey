import Foundation

/// 多语言文本：目录里每个字段都写 zh 和 en，界面按系统语言取
struct LocalizedText: Codable, Hashable {
    var zh: String
    var en: String?
    var value: String { L.isChinese ? zh : (en ?? zh) }
}

struct LocalizedTags: Codable, Hashable {
    var zh: [String]
    var en: [String]?
    var value: [String] { L.isChinese ? zh : (en ?? zh) }
}

struct MarketCategory: Codable, Hashable, Identifiable {
    var id: String
    var name: LocalizedText
    var icon: String
}

struct MarketPrompt: Codable, Hashable, Identifiable {
    var id: String
    var category: String
    var title: LocalizedText
    var summary: LocalizedText
    var body: LocalizedText
    var tags: LocalizedTags
    var featured: Bool? = false
}

struct MarketCatalog: Codable {
    var version: Int
    var updatedAt: String
    var categories: [MarketCategory]
    var prompts: [MarketPrompt]
}
