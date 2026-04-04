import XCTest
@testable import MacTextActionsApp

@MainActor
final class AppShellViewModelTests: XCTestCase {
    func testGlobalShortcutHintUsesChineseGuidanceWhenPermissionMissing() {
        let permissionStatusProvider = PermissionStatusProviderStub(
            accessibilityAuthorized: false,
            inputMonitoringAuthorized: true
        )
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: permissionStatusProvider
        )

        XCTAssertEqual(
            viewModel.globalShortcutHint,
            "需要同时开启辅助功能与输入监听权限，快捷键才能全局生效。"
        )
    }
}

private struct PermissionStatusProviderStub: PermissionStatusProviding {
    let accessibilityAuthorized: Bool
    let inputMonitoringAuthorized: Bool

    func isAccessibilityAuthorized() -> Bool {
        accessibilityAuthorized
    }

    func isInputMonitoringAuthorized() -> Bool {
        inputMonitoringAuthorized
    }
}
