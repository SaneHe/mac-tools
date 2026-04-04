import AppKit
import SwiftUI

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    var onOpenWorkspaceClicked: (() -> Void)?
    var onSettingsClicked: (() -> Void)?
    var menuItems: [NSMenuItem] {
        statusItem?.menu?.items ?? []
    }
    var statusItemButton: NSStatusBarButton? {
        statusItem?.button
    }

    override init() {
        super.init()
        setupStatusItem()
    }

    func setVisible(_ visible: Bool) {
        if visible {
            if statusItem == nil {
                setupStatusItem()
            }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = AppIconFactory.makeStatusBarIcon()
        }

        let menu = NSMenu()
        menu.addItem(makeMenuItem(title: "打开工具", action: #selector(openWorkspaceClicked), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: "设置...", action: #selector(settingsClicked), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: "退出", action: #selector(quitClicked), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func makeMenuItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    @objc private func settingsClicked() {
        onSettingsClicked?()
    }

    @objc private func openWorkspaceClicked() {
        onOpenWorkspaceClicked?()
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}
