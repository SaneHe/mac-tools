import AppKit
import SwiftUI

protocol RunningApplicationActivating: AnyObject {
    func activate(options: NSApplication.ActivationOptions) -> Bool
}

extension NSRunningApplication: RunningApplicationActivating {}

protocol FrontmostApplicationManaging {
    func currentFrontmostApplication() -> RunningApplicationActivating?
    func activate(_ application: RunningApplicationActivating)
}

struct SystemFrontmostApplicationManager: FrontmostApplicationManaging {
    func currentFrontmostApplication() -> RunningApplicationActivating? {
        NSWorkspace.shared.frontmostApplication
    }

    func activate(_ application: RunningApplicationActivating) {
        _ = application.activate(options: [.activateIgnoringOtherApps])
    }
}

final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var currentExecutionMode: ExecutionMode = .defaultMode
    private let frontmostApplicationManager: FrontmostApplicationManaging
    private weak var menuOpeningFrontmostApplication: RunningApplicationActivating?
    private var shouldRestoreFrontmostApplicationAfterClose = false
    var onOpenWorkspaceClicked: (() -> Void)?
    var onSettingsClicked: (() -> Void)?
    var onExecutionModeChanged: ((ExecutionMode) -> Void)?
    var menuItems: [NSMenuItem] {
        statusItem?.menu?.items ?? []
    }
    var statusItemButton: NSStatusBarButton? {
        statusItem?.button
    }

    init(frontmostApplicationManager: FrontmostApplicationManaging = SystemFrontmostApplicationManager()) {
        self.frontmostApplicationManager = frontmostApplicationManager
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
        menu.delegate = self
        ExecutionMode.allCases.forEach { mode in
            let item = makeExecutionModeMenuItem(for: mode)
            menu.addItem(item)
        }
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: "打开工具", action: #selector(openWorkspaceClicked), keyEquivalent: "o"))
        menu.addItem(makeMenuItem(title: "设置...", action: #selector(settingsClicked), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(makeMenuItem(title: "退出", action: #selector(quitClicked), keyEquivalent: "q"))

        statusItem?.menu = menu
        refreshExecutionModeMenuState()
    }

    private func makeMenuItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func makeExecutionModeMenuItem(for mode: ExecutionMode) -> NSMenuItem {
        let item = NSMenuItem(
            title: mode.menuTitle,
            action: #selector(executionModeClicked(_:)),
            keyEquivalent: mode.keyEquivalent
        )
        item.target = self
        item.keyEquivalentModifierMask = mode.keyEquivalentModifierMask
        item.tag = mode.rawValue
        return item
    }

    private func refreshExecutionModeMenuState() {
        statusItem?.menu?.items.forEach { item in
            guard let mode = ExecutionMode(rawValue: item.tag) else {
                return
            }
            item.state = mode == currentExecutionMode ? .on : .off
        }
    }

    @objc private func settingsClicked() {
        onSettingsClicked?()
    }

    @objc private func openWorkspaceClicked() {
        onOpenWorkspaceClicked?()
    }

    @objc private func executionModeClicked(_ sender: NSMenuItem) {
        guard let mode = ExecutionMode(rawValue: sender.tag) else {
            return
        }

        currentExecutionMode = mode
        shouldRestoreFrontmostApplicationAfterClose = true
        refreshExecutionModeMenuState()
        onExecutionModeChanged?(mode)
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        menuOpeningFrontmostApplication = frontmostApplicationManager.currentFrontmostApplication()
        shouldRestoreFrontmostApplicationAfterClose = false
    }

    func menuDidClose(_ menu: NSMenu) {
        guard shouldRestoreFrontmostApplicationAfterClose,
              let application = menuOpeningFrontmostApplication else {
            menuOpeningFrontmostApplication = nil
            shouldRestoreFrontmostApplicationAfterClose = false
            return
        }

        frontmostApplicationManager.activate(application)
        menuOpeningFrontmostApplication = nil
        shouldRestoreFrontmostApplicationAfterClose = false
    }
}
