import Foundation
import MacTextActionsCore

/// Maps core detection and transform output into view-friendly result panel state.
struct PanelContentFactory {
    private let detector = ContentDetector()
    private let transformEngine = TransformEngine()

    // MARK: - State Mapping

    func makeState(from selectionText: String) -> ResultPanelState {
        let detection = detector.detect(selectionText)
        let result = transformEngine.transform(input: selectionText, detection: detection)

        if result.displayMode == .error {
            // Keep domain failures in a dedicated error state instead of rendering partial content.
            return .error(
                ResultPanelError(
                    title: title(for: detection.kind),
                    message: result.errorMessage ?? "发生未知错误。",
                    recoverySuggestion: recoverySuggestion(for: detection.kind)
                )
            )
        }

        return .content(
            ResultPanelContent(
                title: title(for: detection.kind),
                subtitle: subtitle(for: detection.kind),
                // Actions-only states still show the current selection so the panel remains contextual.
                primaryResult: result.primaryOutput ?? selectionText,
                presentationStyle: presentationStyle(for: result.displayMode),
                actions: result.secondaryActions,
                footerNote: footerNote(for: detection.kind)
            )
        )
    }

    // MARK: - Presentation Copy

    private func title(for kind: ContentKind) -> String {
        switch kind {
        case .json:
            return "JSON"
        case .invalidJSON:
            return "JSON 校验失败"
        case .timestamp:
            return "时间戳"
        case .dateString:
            return "日期字符串"
        case .plainText:
            return "普通文本"
        }
    }

    private func subtitle(for kind: ContentKind) -> String {
        switch kind {
        case .json:
            return "已格式化并完成校验"
        case .invalidJSON:
            return "错误状态"
        case .timestamp:
            return "已转换为本地日期时间"
        case .dateString:
            return "已转换为 Unix 时间戳"
        case .plainText:
            return "选中文本预览"
        }
    }

    private func footerNote(for kind: ContentKind) -> String? {
        switch kind {
        case .json:
            return "可通过次要动作执行 JSON 压缩。"
        case .invalidJSON:
            return nil
        case .timestamp:
            return "结果按本地时间显示。"
        case .dateString:
            return "日期解析策略保持保守。"
        case .plainText:
            return "MD5 和提醒创建需要手动触发。"
        }
    }

    private func recoverySuggestion(for kind: ContentKind) -> String? {
        switch kind {
        case .json, .invalidJSON:
            return "请修正语法后再次触发快捷键。"
        case .timestamp, .dateString, .plainText:
            return "请检查选中文本后重试。"
        }
    }

    // MARK: - Presentation Style

    private func presentationStyle(for mode: DisplayMode) -> PanelPresentationStyle {
        switch mode {
        case .code:
            return .code
        case .text, .actionsOnly:
            return .text
        case .error:
            return .error
        }
    }
}
