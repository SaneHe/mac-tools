import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let contentView = SettingsView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Mac Text Actions"
        window.setContentSize(NSSize(width: 700, height: 500))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.center()

        self.init(window: window)
    }
}
