import Foundation

struct Snippet: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var content: String
    var hotkey: KeyComboData?
    var isEnabled: Bool

    init(id: UUID = UUID(), name: String = "", content: String = "", hotkey: KeyComboData? = nil, isEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.content = content
        self.hotkey = hotkey
        self.isEnabled = isEnabled
    }
}
