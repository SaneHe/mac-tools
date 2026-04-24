import XCTest
@testable import MacTextActionsApp

@MainActor
final class AppShellViewModelTests: XCTestCase {
    func testGlobalShortcutHintUsesChineseGuidanceWhenPermissionMissing() {
        let permissionStatusProvider = PermissionStatusProviderStub(
            accessibilityAuthorized: false
        )
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: permissionStatusProvider
        )

        XCTAssertEqual(
            viewModel.globalShortcutHint,
            "需要先开启辅助功能权限，应用才能读取选区并响应全局快捷键。"
        )
    }
}

private struct PermissionStatusProviderStub: PermissionStatusProviding {
    let accessibilityAuthorized: Bool

    func isAccessibilityAuthorized() -> Bool {
        accessibilityAuthorized
    }
}
