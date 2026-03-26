import Foundation

/// Bridges the app shell to the eventual Accessibility-based selected text reader.
protocol SelectionReading {
    func readSelectedText() -> String?
}

/// Executes explicit result panel actions without coupling the view model to platform APIs.
protocol ActionExecuting {
    func execute(_ action: ResultActionKind, content: ResultPanelContent) -> String
}

struct AppServices {
    let selectionReader: SelectionReading
    let actionExecutor: ActionExecuting

    static func preview() -> AppServices {
        let selectionReader = MockSelectionReader()
        let actionExecutor = MockActionExecutor()
        return AppServices(selectionReader: selectionReader, actionExecutor: actionExecutor)
    }
}

/// Preview-only implementation used by the current scaffold and SwiftUI previews.
final class MockSelectionReader: SelectionReading {
    var selectedText: String?

    func readSelectedText() -> String? {
        selectedText
    }
}

/// Preview-only executor that surfaces action intent as status text.
final class MockActionExecutor: ActionExecuting {
    func execute(_ action: ResultActionKind, content: ResultPanelContent) -> String {
        switch action {
        case .copyResult:
            return "演示模式下已复制\(content.title)结果。"
        case .replaceSelection:
            return "演示模式下已替换当前选中文本。"
        case .compressJSON:
            return "演示模式下已准备压缩后的 JSON。"
        case .generateMD5:
            return "演示模式下已生成 MD5 结果。"
        case .createReminder:
            return "演示模式下已打开提醒创建流程。"
        }
    }
}
