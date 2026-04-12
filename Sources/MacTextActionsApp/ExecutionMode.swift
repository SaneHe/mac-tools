import AppKit

enum ExecutionMode: Int, CaseIterable, Equatable {
    case automatic
    case md5
    case jsonCompress

    var shortcutIndex: Int {
        rawValue + 1
    }

    var menuTitle: String {
        switch self {
        case .automatic:
            return "自动识别"
        case .md5:
            return "MD5"
        case .jsonCompress:
            return "JSON Compress"
        }
    }

    var keyEquivalent: String {
        String(shortcutIndex)
    }

    var keyEquivalentModifierMask: NSEvent.ModifierFlags {
        [.command]
    }

    static var shortcutSummaryText: String {
        let shortcuts = allCases.map { mode in
            "⌘\(mode.shortcutIndex) \(mode.menuTitle)"
        }
        return shortcuts.joined(separator: " / ") + "（菜单展开时切换模式）"
    }

    static let defaultMode: ExecutionMode = .automatic
}
