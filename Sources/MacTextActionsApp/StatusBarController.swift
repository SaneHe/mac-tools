import AppKit
import SwiftUI

final class StatusBarController {
    private var statusItem: NSStatusItem?
    var onSettingsClicked: (() -> Void)?

    init() {
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "Mac Text Actions")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(settingsClicked), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitClicked), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func settingsClicked() {
        onSettingsClicked?()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}
