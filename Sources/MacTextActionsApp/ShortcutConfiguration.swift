import Foundation
import CoreGraphics

/// 可存储的快捷键配置
struct ShortcutConfiguration: Codable, Equatable {
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

        /// 转换为 CGEventFlags
        var cgEventFlags: CGEventFlags {
            var flags: CGEventFlags = []
            if contains(.command) { flags.insert(.maskCommand) }
            if contains(.option) { flags.insert(.maskAlternate) }
            if contains(.control) { flags.insert(.maskControl) }
            if contains(.shift) { flags.insert(.maskShift) }
            if contains(.function) { flags.insert(.maskSecondaryFn) }
            return flags
        }

        /// 从 CGEventFlags 创建
        init(cgFlags: CGEventFlags) {
            var flags: ModifierFlags = []
            if cgFlags.contains(.maskCommand) { flags.insert(.command) }
            if cgFlags.contains(.maskAlternate) { flags.insert(.option) }
            if cgFlags.contains(.maskControl) { flags.insert(.control) }
            if cgFlags.contains(.maskShift) { flags.insert(.shift) }
            if cgFlags.contains(.maskSecondaryFn) { flags.insert(.function) }
            self = flags
        }
    }

    /// 默认配置：Option + Space
    static let `default` = ShortcutConfiguration(
        keyCode: 49, // Space
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
        let keyName = keyCodeToName(keyCode)
        parts.append(keyName)

        return parts.joined(separator: "+")
    }

    private func keyCodeToName(_ code: Int64) -> String {
        switch code {
        case 49: return "Space"
        case 36: return "↩"
        case 48: return "⇥"
        case 53: return "⎋"
        case 51: return "⌫"
        case 117: return "⌦"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 0...9:
            // 字母键 A-Z (对应 ASCII)
            let letters = "ANSI_ANSI_ANSI_ANSI_ANSI_ANSI_ANSI_ANSI_ANSI_ANSI"
            return String(format: "%C", Int(code) + 96)
        default:
            return "Key(\(code))"
        }
    }
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
