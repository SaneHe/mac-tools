import AppKit
import SwiftUI
import MacTextActionsCore

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
        screenFrames: [CGRect]
    ) -> CGRect {
        let screenFrame = screenFrames.first(where: { $0.contains(mouseLocation) }) ?? screenFrames.first
        let size = PopoverAnchorWindowMetrics.anchorSize
        let offset = PopoverAnchorWindowMetrics.anchorOffset
        let rawOrigin = CGPoint(x: mouseLocation.x - offset, y: mouseLocation.y - offset)

        guard let screenFrame else {
            return CGRect(origin: rawOrigin, size: CGSize(width: size, height: size))
        }

        let clampedX = min(
            max(rawOrigin.x, screenFrame.minX),
            screenFrame.maxX - size
        )
        let clampedY = min(
            max(rawOrigin.y, screenFrame.minY),
            screenFrame.maxY - size
        )

        return CGRect(
            x: clampedX,
            y: clampedY,
            width: size,
            height: size
        )
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
        selectedText: String,
        contentSource: SelectionContentSource,
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
            result: result,
            selectedText: selectedText,
            contentSource: contentSource,
            sourceMessage: sourceMessage,
            onCopy: { [weak self] output in
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(output, forType: .string)
                self?.close()
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
        let anchorFrame = PopoverAnchorWindowFrameResolver.resolveFrame(
            mouseLocation: mouseLocation,
            screenFrames: NSScreen.screens.map(\.frame)
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
            preferredEdge: .minY
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
}
