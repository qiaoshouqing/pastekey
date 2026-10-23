import Foundation

/// 多语言文本：目录里每个字段都写 zh 和 en，界面按系统语言取
/// 目录里的多语言文本：zh 是简体，繁体由简体自动转换
struct LocalizedText: Codable, Hashable {
    var zh: String
    var en: String?
    var ja: String?
    var value: String {
        switch L.lang {
        case .zhHans: return zh
        case .zhHant: return L.hant(zh)
        case .ja: return ja ?? en ?? zh
        case .en: return en ?? zh
        }
    }
}

struct LocalizedTags: Codable, Hashable {
    var zh: [String]
    var en: [String]?
    var ja: [String]?
    var value: [String] {
        switch L.lang {
        case .zhHans: return zh
        case .zhHant: return zh.map(L.hant)
        case .ja: return ja ?? en ?? zh
        case .en: return en ?? zh
        }
    }
    var all: [String] { zh + (en ?? []) + (ja ?? []) }
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
