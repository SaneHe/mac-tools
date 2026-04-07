import AppKit
import SwiftUI
import MacTextActionsCore

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

        anchorWindow = NSWindow(
            contentRect: NSRect(x: mouseLocation.x - 10, y: mouseLocation.y - 10, width: 20, height: 20),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        anchorWindow?.isOpaque = false
        anchorWindow?.backgroundColor = .clear
        anchorWindow?.level = .popUpMenu
        anchorWindow?.ignoresMouseEvents = true
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
