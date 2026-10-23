import Foundation

/// 极简双语：系统首选语言是中文就显示中文，否则显示英文
enum L {
    static let isChinese: Bool = {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("zh")
    }()
    static func t(_ zh: String, _ en: String) -> String { isChinese ? zh : en }
}
