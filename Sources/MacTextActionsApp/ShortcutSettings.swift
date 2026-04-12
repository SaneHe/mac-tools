import AppKit
import ApplicationServices
import CoreGraphics

enum AppShortcutConfiguration {
    static let globalShortcutTitle = "全局触发"
    static let globalShortcutValue = "Space"
    static let toolSwitchShortcutTitle = "工具切换"
    static let toolSwitchShortcutValue = ExecutionMode.shortcutSummaryText
    static let primaryActionTitle = "主操作"
    static let primaryActionValue = "Cmd+Enter"
    static let clearActionTitle = "清空"
    static let clearActionValue = "Cmd+Delete"
}

enum PermissionDisplayState: Equatable {
    case granted
    case needsAttention

    var text: String {
        switch self {
        case .granted:
            return "已授权"
        case .needsAttention:
            return "需要在系统设置中开启"
        }
    }

    var symbolName: String {
        switch self {
        case .granted:
            return "checkmark.seal.fill"
        case .needsAttention:
            return "exclamationmark.triangle.fill"
        }
    }
}

protocol PermissionStatusProviding {
    func isAccessibilityAuthorized() -> Bool
    func isInputMonitoringAuthorized() -> Bool
}

struct SystemPermissionStatusProvider: PermissionStatusProviding {
    func isAccessibilityAuthorized() -> Bool {
        AXIsProcessTrusted()
    }

    func isInputMonitoringAuthorized() -> Bool {
        CGPreflightListenEventAccess()
    }
}

protocol PermissionPrompting {
    func requestAccessibilityPermission()
    func requestInputMonitoringPermission()
}

struct SystemPermissionPrompter: PermissionPrompting {
    func requestAccessibilityPermission() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func requestInputMonitoringPermission() {
        _ = CGRequestListenEventAccess()
    }
}
