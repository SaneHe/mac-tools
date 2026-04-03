import AppKit
import SwiftUI
import MacTextActionsCore

final class PopoverController {
    private var popover: NSPopover?
    private var eventMonitor: Any?

    func show(with result: TransformResult, selectedText: String) {
        if popover == nil {
            popover = NSPopover()
            popover?.behavior = .transient
            popover?.animates = true
        }

        let contentView = LiquidGlassPopover(
            result: result,
            selectedText: selectedText,
            onCopy: { [weak self] in
                self?.close()
            },
            onReplace: { [weak self] in
                self?.close()
            },
            onClose: { [weak self] in
                self?.close()
            }
        )

        popover?.contentViewController = NSHostingController(rootView: contentView)
        popover?.show(relativeTo: .zero, of: getFrontmostWindow()?.contentView ?? NSView(), preferredEdge: .maxY)

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    func close() {
        popover?.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func getFrontmostWindow() -> NSWindow? {
        NSApp.orderedWindows.first { $0.isKeyWindow }
    }
}
