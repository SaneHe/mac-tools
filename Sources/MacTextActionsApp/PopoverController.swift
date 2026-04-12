import AppKit
import SwiftUI
import MacTextActionsCore

protocol PopoverInteractionActivating: AnyObject {
    func activate(ignoringOtherApps flag: Bool)
}

extension NSApplication: PopoverInteractionActivating {}

enum PopoverInteractionActivator {
    /// 在读取完选中文本后主动激活应用，避免首次点击只用于聚焦面板。
    static func activate(_ application: PopoverInteractionActivating) {
        application.activate(ignoringOtherApps: true)
    }
}

enum PopoverAnchorWindowMetrics {
    static let anchorSize: CGFloat = 20
    static let anchorOffset: CGFloat = 10
}

enum PopoverAnchorWindowConfiguration {
    static func makeCollectionBehavior() -> NSWindow.CollectionBehavior {
        [.moveToActiveSpace, .transient]
    }
}

enum PopoverAnchorResolver {
    static func resolveAnchorView(
        windowContentView: NSView?,
        statusItemButton: NSStatusBarButton?
    ) -> NSView? {
        if let windowContentView {
            return windowContentView
        }

        return statusItemButton
    }
}

enum PopoverAnchorWindowFrameResolver {
    static func resolveFrame(
        mouseLocation: CGPoint,
        screenFrames: [CGRect],
        visibleScreenFrames: [CGRect]
    ) -> CGRect {
        let clampedFrame = resolveClampedScreenFrame(
            mouseLocation: mouseLocation,
            screenFrames: screenFrames,
            visibleScreenFrames: visibleScreenFrames
        )
        let size = PopoverAnchorWindowMetrics.anchorSize
        let offset = PopoverAnchorWindowMetrics.anchorOffset
        let rawOrigin = CGPoint(x: mouseLocation.x - offset, y: mouseLocation.y - offset)

        guard let clampedFrame else {
            return CGRect(origin: rawOrigin, size: CGSize(width: size, height: size))
        }

        let clampedX = min(
            max(rawOrigin.x, clampedFrame.minX),
            clampedFrame.maxX - size
        )
        let clampedY = min(
            max(rawOrigin.y, clampedFrame.minY),
            clampedFrame.maxY - size
        )

        return CGRect(
            x: clampedX,
            y: clampedY,
            width: size,
            height: size
        )
    }

    private static func resolveClampedScreenFrame(
        mouseLocation: CGPoint,
        screenFrames: [CGRect],
        visibleScreenFrames: [CGRect]
    ) -> CGRect? {
        guard !screenFrames.isEmpty else {
            return visibleScreenFrames.first
        }

        let screenIndex = screenFrames.firstIndex(where: { $0.contains(mouseLocation) }) ?? 0
        if visibleScreenFrames.indices.contains(screenIndex) {
            return visibleScreenFrames[screenIndex]
        }

        return screenFrames[screenIndex]
    }
}

enum PopoverEdgeResolver {
    static func resolvePreferredEdge(
        mouseLocation: CGPoint,
        visibleFrame: CGRect?
    ) -> NSRectEdge {
        guard let visibleFrame else {
            return .minY
        }

        let spaceAbove = visibleFrame.maxY - mouseLocation.y
        let spaceBelow = mouseLocation.y - visibleFrame.minY
        return spaceAbove >= spaceBelow ? .minY : .maxY
    }
}

enum PopoverDismissScheduler {
    static func scheduleAfterCopy(
        delay: TimeInterval = PopoverCopyFeedbackMetrics.dismissDelay,
        action: @escaping () -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: action)
    }
}

final class PopoverController {
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var anchorWindow: NSWindow? // 保持引用

    deinit {
        close()
    }

    func show(
        with result: TransformResult,
        title: String,
        selectedText: String,
        contentSource: SelectionContentSource,
        executionMode: ExecutionMode = .automatic,
        transformContext: TransformContext = TransformContext(),
        sourceMessage: String? = nil,
        statusItemButton: NSStatusBarButton? = nil
    ) {
        // 先关闭之前的
        close()

        popover = NSPopover()
        popover?.behavior = .transient
        popover?.animates = true

        let layout = LiquidGlassPopoverLayout.make(
            result: result,
            selectedText: selectedText
        )
        let contentView = LiquidGlassPopover(
            title: title,
            result: result,
            selectedText: selectedText,
            contentSource: contentSource,
            executionMode: executionMode,
            transformContext: transformContext,
            sourceMessage: sourceMessage,
            onCopy: { [weak self] output in
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(output, forType: .string)
                PopoverDismissScheduler.scheduleAfterCopy {
                    self?.close()
                }
            },
            onReplace: { [weak self] output in
                AccessibilityBridge.shared.replaceSelectedText(with: output)
                self?.close()
            },
            onClose: { [weak self] in
                self?.close()
            },
            layout: layout
        )

        let hostingController = NSHostingController(rootView: contentView)
        // 设置首选内容大小，让 popover 可以自适应
        hostingController.preferredContentSize = NSSize(width: layout.popoverWidth, height: 400)
        popover?.contentViewController = hostingController

        // 在鼠标位置显示 popover
        let mouseLocation = NSEvent.mouseLocation
        let screenFrames = NSScreen.screens.map(\.frame)
        let visibleScreenFrames = NSScreen.screens.map(\.visibleFrame)
        let anchorFrame = PopoverAnchorWindowFrameResolver.resolveFrame(
            mouseLocation: mouseLocation,
            screenFrames: screenFrames,
            visibleScreenFrames: visibleScreenFrames
        )
        let currentVisibleFrame = resolveVisibleFrame(
            mouseLocation: mouseLocation,
            screenFrames: screenFrames,
            visibleScreenFrames: visibleScreenFrames
        )

        anchorWindow = NSWindow(
            contentRect: anchorFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        anchorWindow?.isOpaque = false
        anchorWindow?.backgroundColor = .clear
        anchorWindow?.level = .popUpMenu
        anchorWindow?.ignoresMouseEvents = true
        anchorWindow?.hasShadow = false
        anchorWindow?.collectionBehavior = PopoverAnchorWindowConfiguration.makeCollectionBehavior()
        anchorWindow?.orderFrontRegardless()
        anchorWindow?.orderFront(nil)

        guard let anchorView = anchorWindow?.contentView else {
            return
        }
        popover?.show(
            relativeTo: anchorView.bounds,
            of: anchorView,
            preferredEdge: PopoverEdgeResolver.resolvePreferredEdge(
                mouseLocation: mouseLocation,
                visibleFrame: currentVisibleFrame
            )
        )

        // 点击外部关闭
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    func close() {
        popover?.performClose(nil)
        popover = nil
        anchorWindow?.orderOut(nil)
        anchorWindow = nil
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func getFrontmostWindow() -> NSWindow? {
        NSApp.orderedWindows.first { $0.isKeyWindow }
    }

    private func resolveVisibleFrame(
        mouseLocation: CGPoint,
        screenFrames: [CGRect],
        visibleScreenFrames: [CGRect]
    ) -> CGRect? {
        let screenIndex = screenFrames.firstIndex(where: { $0.contains(mouseLocation) }) ?? 0
        guard visibleScreenFrames.indices.contains(screenIndex) else {
            return visibleScreenFrames.first
        }
        return visibleScreenFrames[screenIndex]
    }
}
