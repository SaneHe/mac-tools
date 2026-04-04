import AppKit
import CryptoKit
import MacTextActionsCore
import SwiftUI

private enum ToolMetrics {
    static let cardSpacing: CGFloat = 18
    static let cardPadding: CGFloat = 24
    static let cardCornerRadius: CGFloat = 18
    static let editorCornerRadius: CGFloat = 14
    static let sectionSpacing: CGFloat = 24
    static let cardContentSpacing: CGFloat = 14
    static let buttonHeight: CGFloat = 40
    static let contentVerticalPadding: CGFloat = 28
    static let contentHorizontalPadding: CGFloat = 28
    static let resultAccessoryButtonSize: CGFloat = 32
    static let floatingActionBarMinHeight: CGFloat = 52
    static let tagTopPadding: CGFloat = 8
    static let resultPlaceholderMinHeight: CGFloat = 80
    static let headerSpacing: CGFloat = 10
    static let contentMaxWidth: CGFloat = 940
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

    // MD5 选项：是否输出大写
    @Published var isMD5Uppercase: Bool = false

    // 时间戳选项：是否使用毫秒
    @Published var useMillisecondTimestamp: Bool = false

    private let outputCopyWriter: OutputCopyWriting

    init(outputCopyWriter: OutputCopyWriting = PasteboardOutputCopyWriter()) {
        self.outputCopyWriter = outputCopyWriter
    }

    func clear() {
        inputText = ""
        outputText = ""
    }

    var hasOutput: Bool {
        !outputText.isEmpty
    }

    func performTransform(for tool: ToolType) {
        switch tool {
        case .timestamp:
            outputText = performTimestampTransform(inputText)

        case .json:
            let detector = ContentDetector()
            let detection = detector.detect(inputText)
            let engine = TransformEngine()
            let result = engine.transform(input: inputText, detection: detection)
            outputText = result.primaryOutput ?? result.errorMessage ?? ""

        case .md5:
            guard let data = inputText.data(using: .utf8) else {
                outputText = "MD5 转换失败"
                return
            }

            let digest = Insecure.MD5.hash(data: data)
            let format = isMD5Uppercase ? "%02X" : "%02x"
            outputText = digest.map { String(format: format, $0) }.joined()

        case .url:
            outputText = UrlTransform.encode(inputText) ?? "URL 编码失败"
        }
    }

    @discardableResult
    func copyOutput() -> Bool {
        guard hasOutput else { return false }

        outputCopyWriter.write(outputText)
        return true
    }

    /// 执行时间戳双向转换：支持时间戳转日期，或日期转时间戳
    private func performTimestampTransform(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // 首先尝试作为时间戳解析（支持秒级和毫秒级）
        if let timestampResult = tryParseTimestamp(trimmed) {
            return timestampResult
        }

        // 然后尝试作为日期字符串解析
        if let dateResult = tryParseDateString(trimmed) {
            return dateResult
        }

        return "无法识别输入格式，请提供有效的时间戳或日期"
    }

    /// 尝试解析时间戳并转换为本地日期时间字符串
    private func tryParseTimestamp(_ input: String) -> String? {
        // 只接受纯数字
        guard input.allSatisfy(\.isNumber),
              let numericValue = Double(input) else {
            return nil
        }

        let interval: TimeInterval
        if input.count == 10 {
            // 10位秒级
            interval = numericValue
        } else if input.count == 13 {
            // 13位毫秒级
            interval = numericValue / 1000.0
        } else {
            return nil
        }

        let date = Date(timeIntervalSince1970: interval)

        // 验证日期是否在合理范围（1970-2100年）
        let calendar = Calendar(identifier: .gregorian)
        let year = calendar.component(.year, from: date)
        guard year >= 1970 && year <= 2100 else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return formatter.string(from: date)
    }

    /// 尝试解析日期字符串并转换为时间戳
    private func tryParseDateString(_ input: String) -> String? {
        // 尝试多种日期格式
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd",
            "yyyy年MM月dd日 HH:mm:ss",
            "yyyy年MM月dd日"
        ]

        let calendar = Calendar(identifier: .gregorian)

        for format in formats {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = format

            if let date = formatter.date(from: input) {
                let timestamp = date.timeIntervalSince1970
                if useMillisecondTimestamp {
                    return String(Int(timestamp * 1000))
                } else {
                    return String(Int(timestamp))
                }
            }
        }

        // 尝试 ISO8601 格式
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: input) {
            let timestamp = date.timeIntervalSince1970
            if useMillisecondTimestamp {
                return String(Int(timestamp * 1000))
            } else {
                return String(Int(timestamp))
            }
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: input) {
            let timestamp = date.timeIntervalSince1970
            if useMillisecondTimestamp {
                return String(Int(timestamp * 1000))
            } else {
                return String(Int(timestamp))
            }
        }

        return nil
    }
}

struct ToolContentView: View {
    let tool: ToolType
    @ObservedObject var viewModel: ToolContentViewModel

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
            if !newValue.isEmpty {
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
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(SettingsChrome.titleColor)

                    Text(tool.summary)
                        .font(.system(size: 14, weight: .medium))
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

                HStack(spacing: 8) {
                    TagView(title: tool.shortTitle)
                    TagView(title: "UTF-8")
                    TagView(title: "Selected Text")
                    Spacer(minLength: 0)
                }
                .padding(.top, ToolMetrics.tagTopPadding)

                // 工具特定选项
                toolOptionsView
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity)
    }

    /// 根据工具类型显示不同的选项
    @ViewBuilder
    private var toolOptionsView: some View {
        switch tool {
        case .md5:
            HStack {
                Toggle("大写输出", isOn: $viewModel.isMD5Uppercase)
                    .toggleStyle(SwitchToggleStyle(tint: SettingsChrome.accent))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .onChange(of: viewModel.isMD5Uppercase) { _ in
                        if !viewModel.inputText.isEmpty {
                            viewModel.performTransform(for: tool)
                        }
                    }
                Spacer()
            }
        case .timestamp:
            HStack {
                Toggle("毫秒时间戳", isOn: $viewModel.useMillisecondTimestamp)
                    .toggleStyle(SwitchToggleStyle(tint: SettingsChrome.accent))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .onChange(of: viewModel.useMillisecondTimestamp) { _ in
                        if !viewModel.inputText.isEmpty {
                            viewModel.performTransform(for: tool)
                        }
                    }
                Spacer()
            }
        default:
            EmptyView()
        }
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

                    copyButton
                }

                resultView
                    .frame(minHeight: tool.resultHeight)

                floatingActionBar
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var copyButton: some View {
        Button {
            viewModel.copyOutput()
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SettingsChrome.secondaryText)
                .frame(
                    width: ToolMetrics.resultAccessoryButtonSize,
                    height: ToolMetrics.resultAccessoryButtonSize
                )
                .background(SettingsChrome.mutedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!resultLayoutState.showsActions)
        .allowsHitTesting(resultLayoutState.showsActions)
        .opacity(resultLayoutState.copyButtonOpacity)
    }

    private var resultView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            if viewModel.hasOutput {
                Text(viewModel.outputText)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(SettingsChrome.titleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: ToolMetrics.resultPlaceholderMinHeight, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(16)
            } else {
                Text("结果会显示在这里")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: ToolMetrics.resultPlaceholderMinHeight, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(16)
            }
        }
        .background(SettingsChrome.mutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: ToolMetrics.editorCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ToolMetrics.editorCornerRadius)
                .stroke(SettingsChrome.editorBorder, lineWidth: SettingsChrome.borderWidth)
        )
    }

    private var floatingActionBar: some View {
        HStack(spacing: 8) {
            actionButton(
                title: "复制结果",
                isPrimary: true,
                shortcut: .init(key: "C", modifiers: [.command, .shift])
            ) {
                viewModel.copyOutput()
            }

            actionButton(title: "继续编辑", isPrimary: false) { }
                .disabled(true)
        }
        .padding(6)
        .background(SettingsChrome.mutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: ToolMetrics.editorCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ToolMetrics.editorCornerRadius, style: .continuous)
                .stroke(SettingsChrome.editorBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .frame(minHeight: ToolMetrics.floatingActionBarMinHeight)
        .opacity(resultLayoutState.actionBarOpacity)
        .allowsHitTesting(resultLayoutState.showsActions)
        .accessibilityHidden(!resultLayoutState.showsActions)
    }

    private var notesSection: some View {
        HStack(spacing: ToolMetrics.cardSpacing) {
            ForEach(tool.supportNotes, id: \.self) { note in
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
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(SettingsChrome.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(SettingsChrome.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
    }

    private func cardHeader(title: String, subtitle: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SettingsChrome.sidebarIcon)
                .frame(width: 28, height: 28)
                .background(SettingsChrome.mutedSurface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: SettingsChrome.compactCornerRadius,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(SettingsChrome.secondaryText)
            }
        }
    }

    private func editor(text: Binding<String>, placeholder: String) -> some View {
        PlaceholderTextEditor(text: text, placeholder: placeholder, minHeight: tool.inputHeight)
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
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isPrimary ? Color.white : SettingsChrome.titleColor)
                .frame(height: ToolMetrics.buttonHeight)
                .frame(minWidth: 80)
                .padding(.horizontal, 14)
                .background(buttonBackground(isPrimary: isPrimary))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .modifier(ActionShortcutModifier(shortcut: shortcut))
    }

    private func buttonBackground(isPrimary: Bool) -> some View {
        Group {
            if isPrimary {
                SettingsChrome.accent
            } else {
                SettingsChrome.cardSurface
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: ToolMetrics.editorCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ToolMetrics.editorCornerRadius, style: .continuous)
                .stroke(
                    isPrimary ? Color.clear : SettingsChrome.editorBorder,
                    lineWidth: SettingsChrome.borderWidth
                )
        )
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
            .background(surfaceColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: ToolMetrics.cardCornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: ToolMetrics.cardCornerRadius)
                    .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
            )
            .shadow(color: SettingsChrome.shadowColor, radius: 18, x: 0, y: 10)
    }
}

private struct TagView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(SettingsChrome.sidebarText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(SettingsChrome.mutedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .stroke(SettingsChrome.editorBorder, lineWidth: SettingsChrome.borderWidth)
            )
    }
}
