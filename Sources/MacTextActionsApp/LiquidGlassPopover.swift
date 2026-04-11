import SwiftUI
import MacTextActionsCore

struct LiquidGlassPopoverWidthPolicy {
    static let minimumWidth: CGFloat = 320
    static let defaultWidth: CGFloat = 420
    static let expandedWidth: CGFloat = 520
    static let largeWidth: CGFloat = 680
    static let maximumWidth: CGFloat = 760

    static func resolve(result: TransformResult, selectedText: String) -> CGFloat {
        let trimmedInput = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let primaryOutput = result.primaryOutput ?? ""
        let longestLineLength = max(
            significantLineLength(in: trimmedInput),
            significantLineLength(in: primaryOutput)
        )
        let dominantLength = max(trimmedInput.count, primaryOutput.count)

        if isCompactTimestampInput(trimmedInput) {
            return minimumWidth
        }

        if result.displayMode == .code {
            if longestLineLength >= 72 || dominantLength >= 220 {
                return largeWidth
            }
            if longestLineLength >= 36 || dominantLength >= 120 {
                return expandedWidth
            }
            return defaultWidth
        }

        if looksLikeURLContent(trimmedInput) || looksLikeURLContent(primaryOutput) {
            if longestLineLength >= 180 || dominantLength >= 320 {
                return maximumWidth
            }
            if longestLineLength >= 90 || dominantLength >= 160 {
                return largeWidth
            }
            if longestLineLength >= 56 || dominantLength >= 96 {
                return expandedWidth
            }
            return defaultWidth
        }

        if dominantLength >= 140 || longestLineLength >= 48 {
            return expandedWidth
        }

        return defaultWidth
    }

    private static func significantLineLength(in text: String) -> Int {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces).count }
            .max() ?? 0
    }

    private static func isCompactTimestampInput(_ text: String) -> Bool {
        let digitsOnly = text.allSatisfy(\.isNumber)
        return digitsOnly && (text.count == 10 || text.count == 13)
    }

    private static func looksLikeURLContent(_ text: String) -> Bool {
        if text.contains("://") || text.hasPrefix("http://") || text.hasPrefix("https://") {
            return true
        }

        return text.hasPrefix("/") && text.contains("?") && text.contains("&")
    }
}

struct LiquidGlassPopoverLayout {
    let showsHeader: Bool
    let popoverWidth: CGFloat

    static let `default` = LiquidGlassPopoverLayout(
        showsHeader: false,
        popoverWidth: LiquidGlassPopoverWidthPolicy.defaultWidth
    )

    static func make(result: TransformResult, selectedText: String) -> LiquidGlassPopoverLayout {
        LiquidGlassPopoverLayout(
            showsHeader: false,
            popoverWidth: LiquidGlassPopoverWidthPolicy.resolve(
                result: result,
                selectedText: selectedText
            )
        )
    }
}

struct LiquidGlassPopoverResultLayout {
    static let previewMinHeight: CGFloat = 96
    static let editingMinHeight: CGFloat = 132
    static let codeBaseHeight: CGFloat = 140
    static let longTextMinHeight: CGFloat = 220
    static let longTextThreshold: Int = 220
    static let longLineThreshold: Int = 120
    static let lineHeight: CGFloat = 22
    static let wrappedCharacterWidth: CGFloat = 8
    static let resultHorizontalPadding: CGFloat = 24
    static let verticalPadding: CGFloat = 32
    static let maximumHeight: CGFloat = 300

    static func minHeight(
        result: TransformResult,
        isEditing: Bool,
        popoverWidth: CGFloat
    ) -> CGFloat {
        let baseHeight = isEditing ? editingMinHeight : previewMinHeight

        guard let output = result.primaryOutput else {
            return baseHeight
        }

        if result.displayMode == .code {
            let lineCount = max(
                output.split(separator: "\n", omittingEmptySubsequences: false).count,
                1
            )
            let contentHeight = CGFloat(lineCount) * lineHeight + verticalPadding
            return min(max(baseHeight, codeBaseHeight, contentHeight), maximumHeight)
        }

        let availableWidth = max(
            popoverWidth - resultHorizontalPadding * 2,
            1
        )
        let charactersPerLine = max(Int(availableWidth / wrappedCharacterWidth), 1)
        let estimatedLineCount = estimateWrappedLineCount(
            output: output,
            charactersPerLine: charactersPerLine
        )
        let contentHeight = CGFloat(estimatedLineCount) * lineHeight + verticalPadding
        let longestLineLength = significantLineLength(in: output)
        let shouldUseLongTextLayout = output.count >= longTextThreshold || longestLineLength >= longLineThreshold
        let targetHeight = shouldUseLongTextLayout
            ? max(baseHeight, longTextMinHeight, contentHeight)
            : max(baseHeight, contentHeight)
        return min(targetHeight, maximumHeight)
    }

    private static func estimateWrappedLineCount(
        output: String,
        charactersPerLine: Int
    ) -> Int {
        output
            .split(separator: "\n", omittingEmptySubsequences: false)
            .reduce(0) { partialResult, line in
                let lineLength = max(line.count, 1)
                let wrappedLineCount = Int(ceil(Double(lineLength) / Double(charactersPerLine)))
                return partialResult + max(wrappedLineCount, 1)
            }
    }

    private static func significantLineLength(in text: String) -> Int {
        text
            .components(separatedBy: "\n")
            .map { $0.count }
            .max() ?? 0
    }
}

struct LiquidGlassPopoverDisplayState: Equatable {
    let primaryOutput: String?
    let errorMessage: String?

    static func make(
        result: TransformResult,
        liveEditResult: TransformResult?,
        isEditing: Bool
    ) -> LiquidGlassPopoverDisplayState {
        if isEditing {
            return LiquidGlassPopoverDisplayState(
                primaryOutput: liveEditResult?.primaryOutput,
                errorMessage: liveEditResult?.errorMessage
            )
        }

        return LiquidGlassPopoverDisplayState(
            primaryOutput: result.primaryOutput,
            errorMessage: result.errorMessage
        )
    }
}

struct LiquidGlassPopoverSourceNoticeState: Equatable {
    let sourceLabel: String?
    let sourceMessage: String?

    static func make(
        contentSource: SelectionContentSource,
        sourceMessage: String?
    ) -> LiquidGlassPopoverSourceNoticeState {
        let shouldHideFallbackLabel = contentSource == .clipboardFallback
            && sourceMessage == "已改用剪贴板内容，不是当前实时选区"

        return LiquidGlassPopoverSourceNoticeState(
            sourceLabel: shouldHideFallbackLabel ? nil : contentSource.displayLabel,
            sourceMessage: sourceMessage
        )
    }
}

struct LiquidGlassPopover: View {
    let title: String
    let result: TransformResult
    let selectedText: String
    let contentSource: SelectionContentSource
    let sourceMessage: String?
    let onCopy: (String) -> Void
    let onReplace: (String) -> Void
    let onClose: () -> Void
    let layout: LiquidGlassPopoverLayout

    private let popoverHeight: CGFloat = 400

    // 窗帘展开动画状态
    @State private var curtainProgress: CGFloat = 0
    @State private var editSession: ReplaceEditSession?
    @State private var liveEditResult: TransformResult?
    @State private var pendingRefreshWorkItem: DispatchWorkItem?

    init(
        title: String,
        result: TransformResult,
        selectedText: String,
        contentSource: SelectionContentSource,
        sourceMessage: String? = nil,
        onCopy: @escaping (String) -> Void,
        onReplace: @escaping (String) -> Void,
        onClose: @escaping () -> Void,
        layout: LiquidGlassPopoverLayout? = nil
    ) {
        self.title = title
        self.result = result
        self.selectedText = selectedText
        self.contentSource = contentSource
        self.sourceMessage = sourceMessage
        self.onCopy = onCopy
        self.onReplace = onReplace
        self.onClose = onClose
        self.layout = layout ?? LiquidGlassPopoverLayout.make(
            result: result,
            selectedText: selectedText
        )
    }

    var body: some View {
        ZStack {
            // 内容容器（带窗帘动画）
            contentView
                // 窗帘效果：从顶部开始向下展开
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: popoverHeight * curtainProgress)
                        Spacer()
                    }
                    .frame(height: popoverHeight)
                )
                // 同时添加轻微的向下位移，增强"放下"的感觉
                .offset(y: (1 - curtainProgress) * (-20))
                .opacity(curtainProgress > 0.01 ? 1 : 0)
        }
        .frame(width: layout.popoverWidth)
        .frame(minHeight: 200, maxHeight: popoverHeight)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            curtainProgress = 0
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2)) {
                curtainProgress = 1.0
            }
        }
        .onDisappear {
            pendingRefreshWorkItem?.cancel()
            pendingRefreshWorkItem = nil
        }
    }

    // MARK: - Content View
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if layout.showsHeader {
                headerView

                Divider()
                    .background(Color.white.opacity(0.2))
            }

            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if isEditing {
                        editableValueSection
                        originalSelectionReferenceSection
                    } else {
                        inputPreviewSection
                    }

                    // 转换结果
                    if let output = displayedPrimaryOutput {
                        resultSection(output: output)
                    }

                    // 错误信息
                    if result.displayMode == .error {
                        errorSection
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: .infinity)

            Divider()
                .background(Color.white.opacity(0.2))

            // Action buttons
            actionBar
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: detectionIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(detectionColor)
                .frame(width: 32, height: 32)
                .background(detectionColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // 标题
            Text(detectionTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)

            Spacer()

            // 关闭按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.7))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Input Preview
    private var inputPreviewSection: some View {
        let sourceNotice = LiquidGlassPopoverSourceNoticeState.make(
            contentSource: contentSource,
            sourceMessage: sourceMessage
        )

        return VStack(alignment: .leading, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                Text("原始文本")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.secondary)
                    .tracking(0.5)

                if let sourceLabel = sourceNotice.sourceLabel {
                    Text(sourceLabel)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary.opacity(0.85))
                }

                if let sourceMessage = sourceNotice.sourceMessage {
                    Text(sourceMessage)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.orange)
                }
            }

            Text(selectedText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.secondary)
                .lineLimit(3)
                .truncationMode(.tail)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var editableValueSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("当前可编辑值")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            PlaceholderTextEditor(
                text: Binding(
                    get: { editSession?.editableText ?? "" },
                    set: { newValue in
                        guard let current = editSession else { return }
                        let nextSession = ReplaceEditSession(
                            mode: current.mode,
                            originalSelectedText: current.originalSelectedText,
                            editableText: newValue,
                            transformContext: current.transformContext
                        )
                        editSession = nextSession
                        scheduleLiveResultRefresh(for: nextSession)
                    }
                ),
                placeholder: "编辑当前转换结果",
                minHeight: 96
            )
        }
    }

    private var originalSelectionReferenceSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("原始选中文本")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            Text(selectedText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.secondary)
                .lineLimit(3)
                .truncationMode(.tail)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Result Section
    private func resultSection(output: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isEditing ? "即时转换结果" : "转换结果")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            SelectableCopyableText(
                text: output,
                minHeight: resultMinHeight
            )
            .frame(
                maxWidth: .infinity,
                minHeight: resultMinHeight,
                alignment: .leading
            )
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.blue.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Error Section
    private var errorSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.orange)

            Text(currentErrorMessage ?? "转换失败")
                .font(.system(size: 13))
                .foregroundStyle(Color.orange)
                .lineLimit(2)

            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: 8) {
            if isEditing {
                Button {
                    if let replacementOutput = currentReplacementOutput {
                        onReplace(replacementOutput)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 11, weight: .medium))
                        Text("应用替换")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(currentReplacementOutput == nil)

                Button {
                    pendingRefreshWorkItem?.cancel()
                    pendingRefreshWorkItem = nil
                    editSession = nil
                    liveEditResult = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                        Text("取消编辑")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .focusable(false)
            } else if let output = result.primaryOutput {
                Button {
                    onCopy(output)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                        Text("复制")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .focusable(false)

                if result.secondaryActions.contains(.replaceSelection) {
                    Button {
                        let session = ReplaceEditSession.begin(
                            selectedText: selectedText,
                            result: result
                        )
                        editSession = session
                        pendingRefreshWorkItem?.cancel()
                        pendingRefreshWorkItem = nil
                        if let session {
                            liveEditResult = session.makeLiveResult(for: session.editableText)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.2.circlepath")
                                .font(.system(size: 11, weight: .medium))
                            Text("替换")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color.white.opacity(0.04))
    }

    private var isEditing: Bool {
        editSession?.mode == .editing
    }

    private var displayedPrimaryOutput: String? {
        displayState.primaryOutput
    }

    private var currentErrorMessage: String? {
        displayState.errorMessage
    }

    private var currentReplacementOutput: String? {
        if isEditing {
            return liveEditResult?.primaryOutput
        }
        return result.primaryOutput
    }

    private var resultMinHeight: CGFloat {
        LiquidGlassPopoverResultLayout.minHeight(
            result: displayResult,
            isEditing: isEditing,
            popoverWidth: layout.popoverWidth
        )
    }

    private func scheduleLiveResultRefresh(for session: ReplaceEditSession) {
        pendingRefreshWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            liveEditResult = session.makeLiveResult(for: session.editableText)
        }
        pendingRefreshWorkItem = workItem

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private var displayState: LiquidGlassPopoverDisplayState {
        LiquidGlassPopoverDisplayState.make(
            result: result,
            liveEditResult: liveEditResult,
            isEditing: isEditing
        )
    }

    private var displayResult: TransformResult {
        if isEditing {
            return liveEditResult ?? result
        }
        return result
    }

    // MARK: - Helpers
    private var detectionTitle: String {
        title
    }

    private var detectionIcon: String {
        if title.contains("JSON") {
            return "curlybraces"
        }
        if title.contains("时间戳") || title.contains("日期") {
            return "clock"
        }
        if title.contains("URL") {
            return "link"
        }
        if title.contains("提醒事项") {
            return "checklist"
        }
        if title.contains("MD5") {
            return "number"
        }

        switch result.displayMode {
        case .error:
            return "exclamationmark.triangle"
        case .actionsOnly:
            return "wand.and.stars"
        case .code, .text:
            return "text.alignleft"
        }
    }

    private var detectionColor: Color {
        if title.contains("JSON") {
            return .purple
        }
        if title.contains("时间戳") || title.contains("日期") {
            return .orange
        }
        if title.contains("URL") {
            return .green
        }
        if title.contains("提醒事项") {
            return .pink
        }
        if title.contains("MD5") {
            return .blue
        }

        switch result.displayMode {
        case .error:
            return .red
        case .actionsOnly:
            return .gray
        case .code, .text:
            return .blue
        }
    }
}
