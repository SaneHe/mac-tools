import AppKit
import Carbon.HIToolbox
import Foundation

/// 可存储的快捷键配置
struct ShortcutConfiguration: Codable, Equatable {
    enum KeyCode {
        static let space: Int64 = 49
    }

    var keyCode: Int64
    var modifiers: ModifierFlags

    struct ModifierFlags: Codable, OptionSet, Equatable {
        let rawValue: UInt32

        static let command = ModifierFlags(rawValue: 1 << 0)
        static let option = ModifierFlags(rawValue: 1 << 1)
        static let control = ModifierFlags(rawValue: 1 << 2)
        static let shift = ModifierFlags(rawValue: 1 << 3)
        static let function = ModifierFlags(rawValue: 1 << 4)

        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }

        /// HotKey 依赖 Carbon 修饰键，不支持 Fn 作为全局快捷键修饰键。
        var carbonFlags: UInt32 {
            var flags: UInt32 = 0
            if contains(.command) { flags |= UInt32(cmdKey) }
            if contains(.option) { flags |= UInt32(optionKey) }
            if contains(.control) { flags |= UInt32(controlKey) }
            if contains(.shift) { flags |= UInt32(shiftKey) }
            return flags
        }

        /// 录制快捷键时只保留 HotKey 可识别的修饰键。
        init(eventFlags: NSEvent.ModifierFlags) {
            var flags: ModifierFlags = []
            if eventFlags.contains(.command) { flags.insert(.command) }
            if eventFlags.contains(.option) { flags.insert(.option) }
            if eventFlags.contains(.control) { flags.insert(.control) }
            if eventFlags.contains(.shift) { flags.insert(.shift) }
            if eventFlags.contains(.function) { flags.insert(.function) }
            self = flags
        }

        var supportedHotKeyModifiers: ModifierFlags {
            intersection([.command, .option, .control, .shift])
        }

        var hasSupportedHotKeyModifier: Bool {
            !supportedHotKeyModifiers.isEmpty
        }

        var usesOnlyOptionOrShift: Bool {
            hasSupportedHotKeyModifier
            && !contains(.command)
            && !contains(.control)
        }
    }

    /// 默认配置：Option + Space
    static let `default` = ShortcutConfiguration(
        keyCode: KeyCode.space,
        modifiers: [.option]
    )

    /// 快捷键的显示名称
    var displayString: String {
        var parts: [String] = []

        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.shift) { parts.append("⇧") }

        // 按键名称
        let keyName = Self.displayName(for: keyCode)
        parts.append(keyName)

        return parts.joined(separator: "+")
    }

    var isSupportedByHotKey: Bool {
        modifiers.hasSupportedHotKeyModifier && !modifiers.contains(.function)
    }

    static func displayName(for code: Int64) -> String {
        if let keyName = keyDisplayNames[code] {
            return keyName
        }

        switch code {
        default:
            return "Key(\(code))"
        }
    }

    private static let keyDisplayNames: [Int64: String] = [
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        4: "H",
        5: "G",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        16: "Y",
        17: "T",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        22: "6",
        23: "5",
        24: "=",
        25: "9",
        26: "7",
        27: "-",
        28: "8",
        29: "0",
        30: "]",
        31: "O",
        32: "U",
        33: "[",
        34: "I",
        35: "P",
        36: "↩",
        37: "L",
        38: "J",
        39: "'",
        40: "K",
        41: ";",
        42: "\\",
        43: ",",
        44: "/",
        45: "N",
        46: "M",
        47: ".",
        48: "⇥",
        49: "Space",
        50: "`",
        51: "⌫",
        53: "⎋",
        117: "⌦",
        123: "←",
        124: "→",
        125: "↓",
        126: "↑"
    ]
}

/// 管理快捷键配置的存储
final class ShortcutSettingsManager: ObservableObject {
    static let shared = ShortcutSettingsManager()

    private let userDefaultsKey = "globalShortcutConfiguration"

    @Published var configuration: ShortcutConfiguration {
        didSet {
            saveConfiguration()
        }
    }

    var onConfigurationChanged: ((ShortcutConfiguration) -> Void)?

    init() {
        self.configuration = Self.loadConfiguration()
    }

    private static func loadConfiguration() -> ShortcutConfiguration {
        guard let data = UserDefaults.standard.data(forKey: "globalShortcutConfiguration"),
              let config = try? JSONDecoder().decode(ShortcutConfiguration.self, from: data) else {
            return .default
        }
        return config
    }

    private func saveConfiguration() {
        if let data = try? JSONEncoder().encode(configuration) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        onConfigurationChanged?(configuration)
    }

    func resetToDefault() {
        configuration = .default
    }
}
