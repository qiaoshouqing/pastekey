import Foundation

/// 提示词里可以写的变量。中英文写法都认。
enum TemplateVariable: String, CaseIterable, Hashable {
    case clipboard, date, time, input

    var tokens: [String] {
        switch self {
        case .clipboard: return ["{{剪贴板}}", "{{clipboard}}", "{{剪貼簿}}"]
        case .date: return ["{{日期}}", "{{date}}"]
        case .time: return ["{{时间}}", "{{time}}", "{{時間}}"]
        case .input: return ["{{输入}}", "{{input}}", "{{輸入}}"]
        }
    }

    var label: String {
        switch self {
        case .clipboard: return L.t("剪贴板内容", "Clipboard", ja: "クリップボード")
        case .date: return L.t("今天日期", "Today's date", ja: "今日の日付")
        case .time: return L.t("现在时间", "Current time", ja: "現在の時刻")
        case .input: return L.t("粘贴前现填", "Ask when pasting", ja: "貼り付け時に入力")
        }
    }

    var insertToken: String {
        switch L.lang {
        case .zhHans: return tokens[0]
        case .zhHant: return tokens.count > 2 ? tokens[2] : tokens[0]
        case .en, .ja: return tokens[1]
        }
    }
}

enum TemplateRenderer {
    static func variables(in body: String) -> [TemplateVariable] {
        TemplateVariable.allCases.filter { v in v.tokens.contains { body.contains($0) } }
    }

    static func render(_ body: String, clipboard: String?, input: String?) -> String {
        var out = body
        let now = Date()
        let dateFmt = DateFormatter(); dateFmt.dateStyle = .medium; dateFmt.timeStyle = .none
        let timeFmt = DateFormatter(); timeFmt.dateStyle = .none; timeFmt.timeStyle = .short
        let values: [TemplateVariable: String] = [
            .clipboard: clipboard ?? "",
            .date: dateFmt.string(from: now),
            .time: timeFmt.string(from: now),
            .input: input ?? "",
        ]
        for (v, value) in values { for t in v.tokens { out = out.replacingOccurrences(of: t, with: value) } }
        return out
    }
}
