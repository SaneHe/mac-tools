import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    convenience init() {
        self.init(viewModel: AppSettingsViewModel())
    }

    convenience init(viewModel: AppSettingsViewModel) {
        let contentView = AppSettingsView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "设置"
        window.setContentSize(NSSize(width: 820, height: 520))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unifiedCompact
        window.center()
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("settingsWindow")

        self.init(window: window)
    }
}
