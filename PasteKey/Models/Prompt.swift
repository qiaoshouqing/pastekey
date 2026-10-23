import Foundation

/// 一条提示词。可以单独绑一个快捷键，按下就直接贴出去。
struct Prompt: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var category: String = ""
    var tags: [String] = []
    var hotkey: KeyCombo?
    var favorite: Bool = false
    var useCount: Int = 0
    var lastUsedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    /// 从市场添加的，记下市场 id，用来显示「已添加」
    var marketID: String?

    var variables: [TemplateVariable] { TemplateRenderer.variables(in: body) }
    var needsInput: Bool { variables.contains(.input) }
}
