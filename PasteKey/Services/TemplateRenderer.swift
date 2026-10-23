import Foundation

/// 提示词里可以写的变量。中英文写法都认。
enum TemplateVariable: String, CaseIterable, Hashable {
    case clipboard, date, time, input

    var tokens: [String] {
        switch self {
        case .clipboard: return ["{{剪贴板}}", "{{clipboard}}"]
        case .date: return ["{{日期}}", "{{date}}"]
        case .time: return ["{{时间}}", "{{time}}"]
        case .input: return ["{{输入}}", "{{input}}"]
        }
    }

    var label: String {
        switch self {
        case .clipboard: return L.t("剪贴板内容", "Clipboard")
        case .date: return L.t("今天日期", "Today's date")
        case .time: return L.t("现在时间", "Current time")
        case .input: return L.t("粘贴前现填", "Ask when pasting")
        }
    }

    var insertToken: String { L.isChinese ? tokens[0] : tokens[1] }
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
