import AppKit
import SwiftUI

private enum EditorLayoutMetrics {
    static let horizontalInset: CGFloat = 16
    static let minimumVerticalInset: CGFloat = 16
    static let defaultFontSize: CGFloat = 14

    static func lineHeight(for font: NSFont?) -> CGFloat {
        guard let font else { return defaultFontSize }
        return ceil(font.ascender - font.descender + font.leading)
    }
}

struct CopyToastStyle {
    let message: String
    let symbolName: String
    let size: NSSize
    let bottomInset: CGFloat
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let fadeInDuration: TimeInterval
    let visibleDuration: TimeInterval
    let fadeOutDuration: TimeInterval
    let initialOffsetY: CGFloat

    static let hud = CopyToastStyle(
        message: "已复制",
        symbolName: "checkmark",
        size: NSSize(width: 92, height: 32),
        bottomInset: 18,
        cornerRadius: 10,
        horizontalPadding: 14,
        fadeInDuration: 0.18,
        visibleDuration: 1.0,
        fadeOutDuration: 0.22,
        initialOffsetY: 6
    )
}

final class CopyToastPresenter {
    private let style: CopyToastStyle
    private weak var toastLabel: NSTextField?

    init(style: CopyToastStyle = .hud) {
        self.style = style
    }

    func show(in containerView: NSView) {
        toastLabel?.removeFromSuperview()

        let label = makeToastLabel()
        label.frame = makeToastFrame(in: containerView.bounds)
        containerView.addSubview(label)
        toastLabel = label

        animateAppearance(for: label)
    }

    private func makeToastLabel() -> NSTextField {
        let label = NSTextField(labelWithString: style.message)
        label.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = NSColor.white.withAlphaComponent(0.96)
        label.alignment = .center
        label.attributedStringValue = makeToastText()
        label.wantsLayer = true
        label.layer?.cornerRadius = style.cornerRadius
        label.layer?.masksToBounds = true
        label.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.72).cgColor
        label.layer?.borderWidth = 1
        label.layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        label.setAccessibilityIdentifier("copy-toast")
        return label
    }

    private func makeToastText() -> NSAttributedString {
        let text = NSMutableAttributedString()

        if let symbolImage = NSImage(
            systemSymbolName: style.symbolName,
            accessibilityDescription: style.message
        ) {
            symbolImage.size = NSSize(width: 11, height: 11)
            let attachment = NSTextAttachment()
            attachment.image = symbolImage
            text.append(NSAttributedString(attachment: attachment))
            text.append(NSAttributedString(string: " "))
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.96)
        ]
        text.append(NSAttributedString(string: style.message, attributes: attributes))
        return text
    }

    private func makeToastFrame(in bounds: NSRect) -> NSRect {
        let width = max(style.size.width, style.size.width + style.horizontalPadding)
        let originX = (bounds.width - width) / 2
        let originY = style.bottomInset
        return NSRect(x: originX, y: originY, width: width, height: style.size.height)
    }

    private func animateAppearance(for label: NSTextField) {
        label.alphaValue = 0
        label.frame.origin.y -= style.initialOffsetY

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = style.fadeInDuration
            label.animator().alphaValue = 1
            label.animator().frame.origin.y += style.initialOffsetY
        }) {
            self.scheduleDismiss(for: label)
        }
    }

    private func scheduleDismiss(for label: NSTextField) {
        DispatchQueue.main.asyncAfter(deadline: .now() + style.visibleDuration) { [weak self] in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = self?.style.fadeOutDuration ?? 0
                label.animator().alphaValue = 0
            }) {
                label.removeFromSuperview()
                if self?.toastLabel === label {
                    self?.toastLabel = nil
                }
            }
        }
    }
}

enum CenteredTextLayout {
    /// 根据内容高度计算稳定的垂直内边距，避免文本切换时出现突跳。
    static func verticalInset(
        minHeight: CGFloat,
        contentHeight: CGFloat,
        minimumInset: CGFloat = EditorLayoutMetrics.minimumVerticalInset
    ) -> CGFloat {
        let availableHeight = minHeight - contentHeight
        let centeredInset = floor(availableHeight / 2)
        return max(minimumInset, centeredInset)
    }
}

/// 自定义文本编辑器，支持细滚动条和垂直居中
struct StyledTextEditor: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        scrollView.verticalScroller?.controlSize = .small
        scrollView.verticalScroller?.scrollerStyle = .overlay

        let textView = CenteredTextView(frame: NSRect(x: 0, y: 0, width: 100, height: minHeight))
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

        textView.delegate = context.coordinator
        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? CenteredTextView else { return }

        textView.minHeight = minHeight
        textView.onTextDidChange = { newText in
            context.coordinator.updateText(newText)
        }

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
            guard let textView = notification.object as? CenteredTextView else { return }
            updateText(textView.string)
        }

        func updateText(_ text: String) {
            parent.text = text
        }
    }
}

/// 支持垂直居中的 TextView
class CenteredTextView: NSTextView {
    var minHeight: CGFloat = 60
    var onTextDidChange: ((String) -> Void)?
    private let toastPresenter = CopyToastPresenter()

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

    private func copySelectedTextToPasteboard() {
        let selectedRange = self.selectedRange()
        guard selectedRange.length > 0,
              let textStorage = self.textStorage else { return }

        let selectedText = (textStorage as NSAttributedString).attributedSubstring(from: selectedRange).string

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)

        toastPresenter.show(in: self)
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
        let verticalInset = CenteredTextLayout.verticalInset(
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

    var body: some View {
        ZStack(alignment: .center) {
            StyledTextEditor(text: $text, placeholder: placeholder, minHeight: minHeight)
                .background(SettingsChrome.mutedSurface)

            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .padding(.horizontal, 20)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: minHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - 输出框双击复制组件

/// 支持双击复制的只读文本视图
struct SelectableCopyableText: NSViewRepresentable {
    let text: String
    let minHeight: CGFloat

    static func makeConfiguredScrollView(text: String, minHeight: CGFloat) -> NSScrollView {
        let scrollView = NSScrollView()
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
        textView.textContainerInset = NSSize(width: EditorLayoutMetrics.horizontalInset, height: 16)

        scrollView.documentView = textView
        return scrollView
    }

    func makeNSView(context: Context) -> NSScrollView {
        Self.makeConfiguredScrollView(text: text, minHeight: minHeight)
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? CopyableTextView else { return }

        textView.minHeight = minHeight
        if textView.string != text {
            textView.string = text
        }
    }
}

/// 支持双击复制的只读 TextView
class CopyableTextView: NSTextView {
    var minHeight: CGFloat = 80
    private let toastPresenter = CopyToastPresenter()

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        if event.clickCount == 2 {
            copySelectedTextToPasteboard()
        }
    }

    private func copySelectedTextToPasteboard() {
        let selectedRange = self.selectedRange()
        guard selectedRange.length > 0,
              let textStorage = self.textStorage else { return }

        let selectedText = (textStorage as NSAttributedString).attributedSubstring(from: selectedRange).string

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(selectedText, forType: .string)

        toastPresenter.show(in: self)
    }
}
