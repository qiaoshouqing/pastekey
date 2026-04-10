import Carbon
import HotKey

struct KeyComboData: Codable, Equatable {
    var carbonKeyCode: UInt32
    var carbonModifiers: UInt32

    var keyCombo: KeyCombo {
        KeyCombo(carbonKeyCode: carbonKeyCode, carbonModifiers: carbonModifiers)
    }

    init(carbonKeyCode: UInt32, carbonModifiers: UInt32) {
        self.carbonKeyCode = carbonKeyCode
        self.carbonModifiers = carbonModifiers
    }

    init(keyCombo: KeyCombo) {
        self.carbonKeyCode = keyCombo.carbonKeyCode
        self.carbonModifiers = keyCombo.carbonModifiers
    }

    var displayString: String {
        var parts: [String] = []
        let mods = carbonModifiers

        if mods & UInt32(controlKey) != 0 { parts.append("⌃") }
        if mods & UInt32(optionKey) != 0 { parts.append("⌥") }
        if mods & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if mods & UInt32(cmdKey) != 0 { parts.append("⌘") }

        // Map common key codes to readable names
        let keyName: String
        switch Int(carbonKeyCode) {
        case kVK_ANSI_A: keyName = "A"
        case kVK_ANSI_S: keyName = "S"
        case kVK_ANSI_D: keyName = "D"
        case kVK_ANSI_F: keyName = "F"
        case kVK_ANSI_G: keyName = "G"
        case kVK_ANSI_H: keyName = "H"
        case kVK_ANSI_J: keyName = "J"
        case kVK_ANSI_K: keyName = "K"
        case kVK_ANSI_L: keyName = "L"
        case kVK_ANSI_Q: keyName = "Q"
        case kVK_ANSI_W: keyName = "W"
        case kVK_ANSI_E: keyName = "E"
        case kVK_ANSI_R: keyName = "R"
        case kVK_ANSI_T: keyName = "T"
        case kVK_ANSI_Y: keyName = "Y"
        case kVK_ANSI_U: keyName = "U"
        case kVK_ANSI_I: keyName = "I"
        case kVK_ANSI_O: keyName = "O"
        case kVK_ANSI_P: keyName = "P"
        case kVK_ANSI_Z: keyName = "Z"
        case kVK_ANSI_X: keyName = "X"
        case kVK_ANSI_C: keyName = "C"
        case kVK_ANSI_V: keyName = "V"
        case kVK_ANSI_B: keyName = "B"
        case kVK_ANSI_N: keyName = "N"
        case kVK_ANSI_M: keyName = "M"
        case kVK_ANSI_1: keyName = "1"
        case kVK_ANSI_2: keyName = "2"
        case kVK_ANSI_3: keyName = "3"
        case kVK_ANSI_4: keyName = "4"
        case kVK_ANSI_5: keyName = "5"
        case kVK_ANSI_6: keyName = "6"
        case kVK_ANSI_7: keyName = "7"
        case kVK_ANSI_8: keyName = "8"
        case kVK_ANSI_9: keyName = "9"
        case kVK_ANSI_0: keyName = "0"
        case kVK_F1: keyName = "F1"
        case kVK_F2: keyName = "F2"
        case kVK_F3: keyName = "F3"
        case kVK_F4: keyName = "F4"
        case kVK_F5: keyName = "F5"
        case kVK_Space: keyName = "Space"
        case kVK_Return: keyName = "↩"
        case kVK_Tab: keyName = "⇥"
        default: keyName = "Key(\(carbonKeyCode))"
        }

        parts.append(keyName)
        return parts.joined()
    }
}
