import AppKit
import SwiftUI
import MacTextActionsCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var popoverController: PopoverController?
    private var keyboardMonitor: KeyboardMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标
        NSApp.setActivationPolicy(.accessory)

        // 初始化状态栏
        statusBarController = StatusBarController()
        statusBarController?.onSettingsClicked = { [weak self] in
            self?.showSettings()
        }

        // 初始化气泡控制器
        popoverController = PopoverController()

        // 初始化键盘监听
        keyboardMonitor = KeyboardMonitor()
        keyboardMonitor?.onSpacePressed = { [weak self] in
            self?.handleSpaceTrigger()
        }
        keyboardMonitor?.start()

        // 请求辅助功能权限
        requestAccessibilityPermission()
    }

    private func showSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func handleSpaceTrigger() {
        guard let selectedText = AccessibilityBridge.shared.readSelectedText(),
              !selectedText.isEmpty else {
            return
        }

        // 检测并显示气泡
        let detector = ContentDetector()
        let detection = detector.detect(selectedText)
        let engine = TransformEngine()
        let result = engine.transform(input: selectedText, detection: detection)

        popoverController?.show(with: result, selectedText: selectedText)
    }

    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
