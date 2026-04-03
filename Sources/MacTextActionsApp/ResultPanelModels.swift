import Foundation
import MacTextActionsCore

/// Sample states that let the current app scaffold exercise the result panel without live integrations.
enum DemoScenario: String, CaseIterable, Identifiable {
    case json
    case timestamp
    case dateString
    case plainText
    case invalidJSON

    var id: String { rawValue }

    var title: String {
        switch self {
        case .json:
            return "JSON"
        case .timestamp:
            return "时间戳"
        case .dateString:
            return "日期"
        case .plainText:
            return "普通文本"
        case .invalidJSON:
            return "无效 JSON"
        }
    }

    var sampleSelectionText: String {
        switch self {
        case .json:
            return "{\"name\":\"MacTextActions\",\"version\":1,\"enabled\":true}"
        case .timestamp:
            return "1711440000"
        case .dateString:
            return "2026-03-26 20:30:00"
        case .plainText:
            return "记得提交季度报告"
        case .invalidJSON:
            return "{\"broken\": true,"
        }
    }
}

enum PanelPresentationStyle: Equatable {
    case text
    case code
    case error
}

/// The app layer reuses the core secondary action model as its button/action identifier.
typealias ResultActionKind = SecondaryAction

extension SecondaryAction: @retroactive Identifiable {
    public var id: String { rawValue }

    var title: String {
        switch self {
        case .copyResult:
            return "复制结果"
        case .replaceSelection:
            return "替换选中文本"
        case .compressJSON:
            return "压缩 JSON"
        case .generateMD5:
            return "生成 MD5"
        case .createReminder:
            return "创建提醒"
        case .urlEncode:
            return "URL 编码"
        case .urlDecode:
            return "URL 解码"
        }
    }

    var systemImageName: String {
        switch self {
        case .copyResult:
            return "doc.on.doc"
        case .replaceSelection:
            return "text.cursor"
        case .compressJSON:
            return "arrow.down.to.line.compact"
        case .generateMD5:
            return "number"
        case .createReminder:
            return "bell.badge"
        case .urlEncode:
            return "link"
        case .urlDecode:
            return "link.badge.plus"
        }
    }
}

struct ResultPanelContent: Equatable {
    let title: String
    let subtitle: String
    let primaryResult: String
    let presentationStyle: PanelPresentationStyle
    let actions: [ResultActionKind]
    let footerNote: String?
}

struct ResultPanelError: Equatable {
    let title: String
    let message: String
    let recoverySuggestion: String?
}

/// Top-level view state for the floating result panel.
enum ResultPanelState: Equatable {
    case loading(title: String, subtitle: String)
    case content(ResultPanelContent)
    case error(ResultPanelError)

    var primaryResult: String? {
        switch self {
        case .content(let content):
            return content.primaryResult
        case .loading, .error:
            return nil
        }
    }
}
