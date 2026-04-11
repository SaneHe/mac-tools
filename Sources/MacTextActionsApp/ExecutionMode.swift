import AppKit

enum ExecutionMode: Int, CaseIterable, Equatable {
    case automatic
    case jsonFormat
    case jsonCompress
    case timestampToLocalDateTime
    case dateToTimestamp
    case md5
    case createReminder

    var menuTitle: String {
        switch self {
        case .automatic:
            return "自动识别"
        case .jsonFormat:
            return "JSON 格式化"
        case .jsonCompress:
            return "JSON Compress"
        case .timestampToLocalDateTime:
            return "时间戳转本地时间"
        case .dateToTimestamp:
            return "日期转时间戳"
        case .md5:
            return "MD5"
        case .createReminder:
            return "创建提醒事项"
        }
    }

    var keyEquivalent: String {
        switch self {
        case .automatic:
            return "1"
        case .jsonFormat:
            return "3"
        case .jsonCompress:
            return "4"
        case .timestampToLocalDateTime:
            return "5"
        case .dateToTimestamp:
            return "6"
        case .md5:
            return "7"
        case .createReminder:
            return "2"
        }
    }

    var keyEquivalentModifierMask: NSEvent.ModifierFlags {
        [.command]
    }

    static let defaultMode: ExecutionMode = .automatic
}
