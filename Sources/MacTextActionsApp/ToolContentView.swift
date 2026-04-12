import AppKit
import MacTextActionsCore
import SwiftUI

private enum ToolMetrics {
    static let cardSpacing: CGFloat = 16
    static let cardPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 22
    static let editorCornerRadius: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let cardContentSpacing: CGFloat = 10
    static let buttonHeight: CGFloat = 32
    static let contentVerticalPadding: CGFloat = 22
    static let contentHorizontalPadding: CGFloat = 22
    static let floatingActionBarMinHeight: CGFloat = 40
    static let resultPlaceholderMinHeight: CGFloat = 72
    static let headerSpacing: CGFloat = 6
    static let contentMaxWidth: CGFloat = 920
}

struct ResultPanelLayoutState: Equatable {
    let showsActions: Bool
    let copyButtonOpacity: Double
    let actionBarOpacity: Double

    static func make(hasOutput: Bool) -> ResultPanelLayoutState {
        ResultPanelLayoutState(
            showsActions: hasOutput,
            copyButtonOpacity: hasOutput ? 1 : 0,
            actionBarOpacity: hasOutput ? 1 : 0
        )
    }
}

protocol OutputCopyWriting {
    func write(_ text: String)
}

private struct PasteboardOutputCopyWriter: OutputCopyWriting {
    func write(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

@MainActor
final class ToolContentViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var outputText: String = ""
    @Published private(set) var optionActionTitle: String?

    private let outputCopyWriter: OutputCopyWriting
    private var currentOptionAction: OptionAction?
    private var transformContext: TransformContext = TransformContext()

    init(outputCopyWriter: OutputCopyWriting = PasteboardOutputCopyWriter()) {
        self.outputCopyWriter = outputCopyWriter
    }

    func clear() {
        inputText = ""
        outputText = ""
        optionActionTitle = nil
        currentOptionAction = nil
        transformContext = TransformContext()
    }

    var hasOutput: Bool {
        !outputText.isEmpty
    }

    func performTransform(for tool: ToolType) {
        if shouldResetContext(for: tool) {
            transformContext = defaultTransformContext(for: tool)
        }

        switch tool {
        case .timestamp:
            let detector = ContentDetector()
            let detection = detector.detect(inputText)
            let engine = TransformEngine()
            let result = engine.transform(
                input: inputText,
                detection: detection,
                context: transformContext
            )
            apply(result: result)

        case .json:
            let detector = ContentDetector()
            let detection = detector.detect(inputText)
            let engine = TransformEngine()
            let result = engine.transform(input: inputText, detection: detection)
            apply(result: result)

        case .md5:
            let engine = TransformEngine()
            let result = engine.transformMD5(input: inputText, context: transformContext)
            apply(result: result)

        case .url:
            outputText = UrlTransform.encode(inputText) ?? "URL 编码失败"
            optionActionTitle = nil
            currentOptionAction = nil
        }
    }

    func toggleOptionAction(for tool: ToolType) {
        guard let nextContext = currentOptionAction?.nextContext else { return }
        transformContext = nextContext
        performTransform(for: tool)
    }

    @discardableResult
    func copyOutput() -> Bool {
        guard hasOutput else { return false }

        outputCopyWriter.write(outputText)
        return true
    }

    private func apply(result: TransformResult) {
        outputText = result.primaryOutput ?? result.errorMessage ?? ""
        currentOptionAction = result.optionAction
        optionActionTitle = result.optionAction?.buttonTitle
    }

    private func defaultTransformContext(for tool: ToolType) -> TransformContext {
        switch tool {
        case .timestamp:
            return TransformContext(timestampPrecision: .seconds)
        case .md5:
            return TransformContext(md5LetterCase: .lowercase)
        case .json, .url:
            return TransformContext()
        }
    }

    private func shouldResetContext(for tool: ToolType) -> Bool {
        switch tool {
        case .timestamp, .md5:
            currentOptionAction == nil
        case .json, .url:
            false
        }
    }
}

struct ToolContentView: View {
    let tool: ToolType
    @ObservedObject var viewModel: ToolContentViewModel
    let onCopyOutput: (() -> Bool)?

    init(
        tool: ToolType,
        viewModel: ToolContentViewModel,
        onCopyOutput: (() -> Bool)? = nil
    ) {
        self.tool = tool
        self.viewModel = viewModel
        self.onCopyOutput = onCopyOutput
    }

    private var resultLayoutState: ResultPanelLayoutState {
        ResultPanelLayoutState.make(hasOutput: viewModel.hasOutput)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: ToolMetrics.sectionSpacing) {
                heroHeader
                contentSection
                Spacer()
                notesSection
            }
            .frame(maxWidth: ToolMetrics.contentMaxWidth, alignment: .leading)
            .padding(.horizontal, ToolMetrics.contentHorizontalPadding)
            .padding(.vertical, ToolMetrics.contentVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(SettingsChrome.workspaceBackground)
        .onChange(of: viewModel.inputText) { newValue in
            if newValue.isEmpty {
                viewModel.clear()
            } else {
                viewModel.performTransform(for: tool)
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: ToolMetrics.headerSpacing) {
            Text(tool.shortTitle.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(SettingsChrome.tertiaryText)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tool.rawValue)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(SettingsChrome.titleColor)

                    Text(tool.summary)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SettingsChrome.secondaryText)
                }

                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    actionButton(
                        title: tool.actionTitle,
                        isPrimary: true,
                        shortcut: .init(key: .return, modifiers: [.command])
                    ) {
                        viewModel.performTransform(for: tool)
                    }

                    actionButton(
                        title: "清空",
                        isPrimary: false,
                        shortcut: .init(key: .delete, modifiers: [.command])
                    ) {
                        viewModel.clear()
                    }
                }
            }
        }
    }

    private var contentSection: some View {
        HStack(alignment: .top, spacing: ToolMetrics.cardSpacing) {
            inputCard
            resultCard
        }
    }

    private var inputCard: some View {
        ToolSurfaceCard {
            VStack(alignment: .leading, spacing: ToolMetrics.cardContentSpacing) {
                cardHeader(
                    title: "输入内容",
                    subtitle: tool.placeholder,
                    symbol: "square.and.pencil"
                )

                editor(text: $viewModel.inputText, placeholder: tool.placeholder)
                    .frame(minHeight: tool.inputHeight, maxHeight: tool.inputHeight)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity)
    }

    private var resultCard: some View {
        ToolSurfaceCard(surfaceColor: SettingsChrome.cardSurface) {
            VStack(alignment: .leading, spacing: ToolMetrics.cardContentSpacing) {
                HStack(alignment: .top, spacing: 12) {
                    cardHeader(
                        title: tool.resultTitle,
                        subtitle: "处理后在这里查看结果",
                        symbol: "sparkles.rectangle.stack"
                    )

                    Spacer(minLength: 0)
                }

                resultView
                    .frame(minHeight: tool.resultHeight)

                floatingActionBar
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var resultView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.hasOutput {
                SelectableCopyableText(
                    text: viewModel.outputText,
                    minHeight: ToolMetrics.resultPlaceholderMinHeight,
                    onCopySucceeded: {
                        _ = triggerCopyOutput()
                    }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("结果会显示在这里")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: ToolMetrics.resultPlaceholderMinHeight, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(14)
            }
        }
        .toolFieldSurface(.workspace)
    }

    private var floatingActionBar: some View {
        HStack(spacing: 6) {
            actionButton(
                title: "复制结果",
                isPrimary: true,
                shortcut: .init(key: "C", modifiers: [.command, .shift])
            ) {
                _ = triggerCopyOutput()
            }

            if let optionActionTitle = viewModel.optionActionTitle {
                actionButton(title: optionActionTitle, isPrimary: false) {
                    viewModel.toggleOptionAction(for: tool)
                }
            }
        }
        .padding(3)
        .toolFieldSurface(.workspace)
        .frame(minHeight: ToolMetrics.floatingActionBarMinHeight)
        .opacity(resultLayoutState.actionBarOpacity)
        .allowsHitTesting(resultLayoutState.showsActions)
        .accessibilityHidden(!resultLayoutState.showsActions)
    }

    private var notesSection: some View {
        HStack(spacing: ToolMetrics.cardSpacing) {
            ForEach(tool.supportNotes.prefix(2), id: \.self) { note in
                noteCard(text: note)
            }
        }
    }

    private func noteCard(text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.green)

            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(SettingsChrome.secondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(SettingsChrome.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
    }

    private func cardHeader(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            SurfaceIconBadge(systemName: symbol)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(SettingsChrome.secondaryText)
            }
        }
    }

    private func editor(text: Binding<String>, placeholder: String) -> some View {
        PlaceholderTextEditor(
            text: text,
            placeholder: placeholder,
            minHeight: tool.inputHeight,
            surfaceStyle: .workspace
        )
            .frame(minHeight: tool.inputHeight)
    }

    private func actionButton(
        title: String,
        isPrimary: Bool,
        shortcut: ActionShortcut? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .frame(height: ToolMetrics.buttonHeight)
                .frame(minWidth: 74)
                .padding(.horizontal, 10)
        }
        .surfaceButtonStyle(isPrimary ? .primary : .secondary)
        .focusable(false)
        .modifier(ActionShortcutModifier(shortcut: shortcut))
    }

    @discardableResult
    private func triggerCopyOutput() -> Bool {
        if let onCopyOutput {
            return onCopyOutput()
        }

        return viewModel.copyOutput()
    }
}

private struct ActionShortcut {
    let key: KeyEquivalent
    let modifiers: EventModifiers
}

private struct ActionShortcutModifier: ViewModifier {
    let shortcut: ActionShortcut?

    func body(content: Content) -> some View {
        guard let shortcut else { return AnyView(content) }
        return AnyView(
            content.keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
        )
    }
}

private struct ToolSurfaceCard<Content: View>: View {
    let surfaceColor: Color
    @ViewBuilder var content: Content

    init(
        surfaceColor: Color = SettingsChrome.cardSurface,
        @ViewBuilder content: () -> Content
    ) {
        self.surfaceColor = surfaceColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(ToolMetrics.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(
                    cornerRadius: ToolMetrics.cardCornerRadius,
                    style: .continuous
                )
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(
                        cornerRadius: ToolMetrics.cardCornerRadius,
                        style: .continuous
                    )
                    .fill(surfaceColor.opacity(0.35))
                )
            }
            .overlay(
                RoundedRectangle(cornerRadius: ToolMetrics.cardCornerRadius)
                    .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
            )
            .shadow(color: SettingsChrome.shadowColor, radius: 12, x: 0, y: 5)
    }
}
