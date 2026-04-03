import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标，变为菜单栏 App
        NSApp.setActivationPolicy(.accessory)
    }
}