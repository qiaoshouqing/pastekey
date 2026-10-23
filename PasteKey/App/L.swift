import Foundation

/// 四种界面语言：简体中文、繁体中文、英语、日语。
/// 跟随系统（含「系统设置 › 通用 › 语言与地区」里给单个 App 选的语言）。
/// 繁体由简体自动转换，再用一张台湾常用词表修正。
enum L {
    enum Lang { case zhHans, zhHant, en, ja }

    static let lang: Lang = {
        let code = (Bundle.main.preferredLocalizations.first ?? Locale.preferredLanguages.first ?? "en").lowercased()
        if code.hasPrefix("zh") {
            if code.contains("hant") || code.hasSuffix("-tw") || code.hasSuffix("-hk") || code.hasSuffix("-mo") { return .zhHant }
            return .zhHans
        }
        if code.hasPrefix("ja") { return .ja }
        return .en
    }()

    static var isChinese: Bool { lang == .zhHans || lang == .zhHant }

    /// 界面文字：写简体和英文，日文可选（缺了用英文）
    static func t(_ zh: String, _ en: String, ja: String? = nil) -> String {
        switch lang {
        case .zhHans: return zh
        case .zhHant: return hant(zh)
        case .ja: return ja ?? en
        case .en: return en
        }
    }

    private static var cache: [String: String] = [:]
    private static let lock = NSLock()

    /// 简体转繁体，再修正成台湾习惯用语
    static func hant(_ s: String) -> String {
        lock.lock(); defer { lock.unlock() }
        if let hit = cache[s] { return hit }
        var out = s.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? s
        for (a, b) in glossary { out = out.replacingOccurrences(of: a, with: b) }
        cache[s] = out
        return out
    }

    private static let glossary: [(String, String)] = [
        ("剪貼板", "剪貼簿"), ("設置", "設定"), ("快捷鍵", "快速鍵"), ("粘貼", "貼上"), ("菜單欄", "選單列"),
        ("菜單", "選單"), ("視頻", "影片"), ("默認", "預設"), ("導出", "匯出"), ("導入", "匯入"),
        ("信息", "資訊"), ("用戶", "使用者"), ("搜索", "搜尋"), ("網絡", "網路"), ("程序", "程式"),
        ("屏幕", "螢幕"), ("代碼", "程式碼"), ("優化", "最佳化"), ("質量", "品質"), ("文件夾", "資料夾"),
        ("文件", "檔案"), ("輔助功能", "輔助使用"), ("隱私與安全性", "隱私權與安全性"), ("應用程序", "應用程式"),
        ("登錄", "登入"), ("賬號", "帳號"), ("郵件", "郵件"), ("短視頻", "短影音"), ("博客", "部落格"),
        ("數據", "資料"), ("軟件", "軟體"), ("項目", "專案"), ("激活", "啟用"), ("支持", "支援"), ("編程", "程式設計"),
    ]
}
