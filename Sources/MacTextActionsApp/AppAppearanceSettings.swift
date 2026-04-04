import AppKit
import Combine

/// 应用外观显示设置
final class AppAppearanceSettings: ObservableObject {
    static let shared = AppAppearanceSettings()

    private let dockIconVisibleKey = "dockIconVisible"
    private let menuBarIconVisibleKey = "menuBarIconVisible"

    /// 是否在 Dock 中显示图标
    @Published var dockIconVisible: Bool {
        didSet {
            UserDefaults.standard.set(dockIconVisible, forKey: dockIconVisibleKey)
            applyDockIconVisibility()
        }
    }

    /// 是否在菜单栏中显示图标
    @Published var menuBarIconVisible: Bool {
        didSet {
            UserDefaults.standard.set(menuBarIconVisible, forKey: menuBarIconVisibleKey)
            applyMenuBarIconVisibility()
        }
    }

    init() {
        self.dockIconVisible = UserDefaults.standard.object(forKey: dockIconVisibleKey) as? Bool ?? false
        self.menuBarIconVisible = UserDefaults.standard.object(forKey: menuBarIconVisibleKey) as? Bool ?? true
    }

    /// 应用 Dock 图标可见性设置
    func applyDockIconVisibility() {
        let policy: NSApplication.ActivationPolicy = dockIconVisible ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
    }

    /// 应用菜单栏图标可见性设置
    func applyMenuBarIconVisibility() {
        // 通知 AppDelegate 更新状态栏显示
        NotificationCenter.default.post(
            name: .menuBarVisibilityChanged,
            object: nil,
            userInfo: ["visible": menuBarIconVisible]
        )
    }
}

extension Notification.Name {
    static let menuBarVisibilityChanged = Notification.Name("menuBarVisibilityChanged")
}
