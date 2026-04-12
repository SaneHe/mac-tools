import AppKit
import SwiftUI

private enum EditorLayoutMetrics {
    static let horizontalInset: CGFloat = 16
    static let minimumVerticalInset: CGFloat = 16
    static let placeholderHorizontalInset: CGFloat = horizontalInset + 5
    static let defaultFontSize: CGFloat = 14

    static func lineHeight(for font: NSFont?) -> CGFloat {
        guard let font else { return defaultFontSize }
        return ceil(font.ascender - font.descender + font.leading)
    }
}

enum EditorTextLayout {
    /// 工具页输入框采用稳定的顶部内边距，避免短文本在大输入框内悬浮在中间。
    static func verticalInset(
        minHeight: CGFloat,
        contentHeight: CGFloat,
        minimumInset: CGFloat = EditorLayoutMetrics.minimumVerticalInset
    ) -> CGFloat {
        _ = minHeight
        _ = contentHeight
        return minimumInset
    }
}

/// 统一工具页内层输入区、结果区和动作条的表面样式。
struct ToolFieldSurfaceStyle {
    let fillColor: Color
    let borderColor: Color
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    static let plain = ToolFieldSurfaceStyle(
        fillColor: .clear,
        borderColor: .clear,
        cornerRadius: 0,
        borderWidth: 0
    )

    static let workspace = ToolFieldSurfaceStyle(
        fillColor: SettingsChrome.surface.opacity(0.88),
        borderColor: SettingsChrome.editorBorder,
        cornerRadius: 16,
        borderWidth: SettingsChrome.borderWidth
    )

    static let popover = ToolFieldSurfaceStyle(
        fillColor: Color.white.opacity(0.08),
        borderColor: Color.white.opacity(0.16),
        cornerRadius: 12,
        borderWidth: 1
    )
}

private struct ToolFieldSurfaceModifier: ViewModifier {
    let style: ToolFieldSurfaceStyle

    func body(content: Content) -> some View {
        content
            .background(style.fillColor)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
    }
}

extension View {
    func toolFieldSurface(_ style: ToolFieldSurfaceStyle) -> some View {
        modifier(ToolFieldSurfaceModifier(style: style))
    }
}

/// 为 AppKit 文本滚动容器提供稳定的最小固有高度，避免 SwiftUI 在结果区把内容压扁。
final class MinimumHeightScrollView: NSScrollView {
    var minimumContentHeight: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(
            width: NSView.noIntrinsicMetric,
            height: max(super.intrinsicContentSize.height, minimumContentHeight)
        )
    }

    override var fittingSize: NSSize {
        let baseSize = super.fittingSize
        return NSSize(
            width: baseSize.width,
            height: max(baseSize.height, minimumContentHeight)
        )
    }
}

/// 自定义文本编辑器，支持细滚动条和稳定的顶部起始排版。
struct StyledTextEditor: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let onCopySucceeded: (() -> Void)?

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = MinimumHeightScrollView()
        scrollView.minimumContentHeight = minHeight
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        scrollView.verticalScroller?.controlSize = .small
        scrollView.verticalScroller?.scrollerStyle = .overlay

        let textView = EditorTextView(frame: NSRect(x: 0, y: 0, width: 100, height: minHeight))
        textView.minHeight = minHeight
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: minHeight)
        textView.updateTextContainerInset()
        textView.onTextDidChange = { newText in
            context.coordinator.updateText(newText)
        }
        textView.onCopySucceeded = onCopySucceeded

        textView.delegate = context.coordinator
        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? EditorTextView else { return }

        (scrollView as? MinimumHeightScrollView)?.minimumContentHeight = minHeight
        textView.minHeight = minHeight
        textView.onTextDidChange = { newText in
            context.coordinator.updateText(newText)
        }
        textView.onCopySucceeded = onCopySucceeded

        if textView.string != text {
            textView.string = text
        }

        textView.updateTextContainerInset()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: StyledTextEditor

        init(_ parent: StyledTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? EditorTextView else { return }
            updateText(textView.string)
        }

        func updateText(_ text: String) {
            parent.text = text
        }
    }
}

/// 为工具页编辑框提供稳定顶部内边距的 TextView。
class EditorTextView: NSTextView {
    var minHeight: CGFloat = 60
    var onTextDidChange: ((String) -> Void)?
    var onCopySucceeded: (() -> Void)?

    override func layout() {
        super.layout()
        updateTextContainerInset()
    }

    override func mouseDown(with event: NSEvent) {
        // 先执行默认的鼠标按下处理（包括文本选择）
        super.mouseDown(with: event)

        // 检测双击：在 mouseDown 中检测，因为文本选择在这里完成
        if event.clickCount == 2 {
            copySelectedTextToPasteboard()
        }
    }

    func copySelectedTextToPasteboardForTesting() {
        copySelectedTextToPasteboard()
    }

    private func copySelectedTextToPasteboard() {
        let selectedRange = self.selectedRange()
        guard selectedRange.length > 0,
              let textStorage = self.textStorage else { return }

        let selectedText = (textStorage as NSAttributedString).attributedSubstring(from: selectedRange).string

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)
        onCopySucceeded?()
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: minHeight)
    }

    override func didChangeText() {
        super.didChangeText()
        onTextDidChange?(string)
        updateTextContainerInset()
    }

    override func paste(_ sender: Any?) {
        super.paste(sender)
        updateTextContainerInset()
    }

    func updateTextContainerInset() {
        guard let layoutManager, let textContainer else { return }

        layoutManager.ensureLayout(for: textContainer)

        let contentHeight = max(
            layoutManager.usedRect(for: textContainer).height,
            EditorLayoutMetrics.lineHeight(for: font)
        )
        let verticalInset = EditorTextLayout.verticalInset(
            minHeight: minHeight,
            contentHeight: contentHeight
        )

        textContainerInset = NSSize(
            width: EditorLayoutMetrics.horizontalInset,
            height: verticalInset
        )
    }
}

/// 带 Placeholder 的文本编辑器包装
struct PlaceholderTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    let onCopySucceeded: (() -> Void)?
    let surfaceStyle: ToolFieldSurfaceStyle

    init(
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat,
        onCopySucceeded: (() -> Void)? = nil,
        surfaceStyle: ToolFieldSurfaceStyle = .plain
    ) {
        _text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.onCopySucceeded = onCopySucceeded
        self.surfaceStyle = surfaceStyle
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            StyledTextEditor(
                text: $text,
                placeholder: placeholder,
                minHeight: minHeight,
                onCopySucceeded: onCopySucceeded
            )

            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .padding(.horizontal, EditorLayoutMetrics.placeholderHorizontalInset)
                    .padding(.top, EditorLayoutMetrics.minimumVerticalInset)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: minHeight)
        .toolFieldSurface(surfaceStyle)
    }
}

// MARK: - 输出框双击复制组件

/// 支持双击复制的只读文本视图
struct SelectableCopyableText: NSViewRepresentable {
    let text: String
    let minHeight: CGFloat
    let onCopySucceeded: (() -> Void)?

    init(
        text: String,
        minHeight: CGFloat,
        onCopySucceeded: (() -> Void)? = nil
    ) {
        self.text = text
        self.minHeight = minHeight
        self.onCopySucceeded = onCopySucceeded
    }

    static func makeConfiguredScrollView(
        text: String,
        minHeight: CGFloat,
        onCopySucceeded: (() -> Void)? = nil
    ) -> NSScrollView {
        let scrollView = MinimumHeightScrollView()
        scrollView.minimumContentHeight = minHeight
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        scrollView.verticalScroller?.controlSize = .small
        scrollView.verticalScroller?.scrollerStyle = .overlay

        let textView = CopyableTextView(frame: NSRect(x: 0, y: 0, width: 100, height: minHeight))
        textView.minHeight = minHeight
        textView.string = text
        textView.isEditable = false
        textView.isSelectable = true
        textView.isRichText = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainerInset = NSSize(
            width: EditorLayoutMetrics.horizontalInset,
            height: EditorLayoutMetrics.minimumVerticalInset
        )
        textView.onCopySucceeded = onCopySucceeded

        scrollView.documentView = textView
        return scrollView
    }

    func makeNSView(context: Context) -> NSScrollView {
        Self.makeConfiguredScrollView(
            text: text,
            minHeight: minHeight,
            onCopySucceeded: onCopySucceeded
        )
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? CopyableTextView else { return }

        (scrollView as? MinimumHeightScrollView)?.minimumContentHeight = minHeight
        textView.minHeight = minHeight
        textView.onCopySucceeded = onCopySucceeded
        if textView.string != text {
            textView.string = text
        }
    }
}

/// 支持双击复制的只读 TextView
class CopyableTextView: NSTextView {
    var minHeight: CGFloat = 80
    var onCopySucceeded: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        if event.clickCount == 2 {
            copySelectedTextToPasteboard()
        }
    }

    func copySelectedTextToPasteboardForTesting() {
        copySelectedTextToPasteboard()
    }

    private func copySelectedTextToPasteboard() {
        let selectedRange = self.selectedRange()
        guard selectedRange.length > 0,
              let textStorage = self.textStorage else { return }

        let selectedText = (textStorage as NSAttributedString).attributedSubstring(from: selectedRange).string

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)
        onCopySucceeded?()
    }
}
