import AppKit
import SwiftUI
import XCTest
@testable import MacTextActionsApp

@MainActor
final class SettingsWindowControllerTests: XCTestCase {
    func testSettingsWindowUsesStandaloneSettingsViewAsRootView() throws {
        let controller = SettingsWindowController(viewModel: AppSettingsViewModel())

        let hostingController = try XCTUnwrap(
            controller.window?.contentViewController as? NSHostingController<AppSettingsView>
        )

        XCTAssertNotNil(hostingController.view)
    }

    func testPermissionOnboardingWindowUsesStandaloneOnboardingViewAsRootView() throws {
        let controller = PermissionOnboardingWindowController(
            viewModel: PermissionOnboardingViewModel(
                permissionStatusProvider: PermissionStatusProviderStub(
                    accessibilityAuthorized: false,
                    inputMonitoringAuthorized: false
                ),
                permissionPrompter: PermissionPrompterStub()
            )
        )

        let hostingController = try XCTUnwrap(
            controller.window?.contentViewController as? NSHostingController<PermissionOnboardingView>
        )

        XCTAssertNotNil(hostingController.view)
    }

    func testPermissionOnboardingWindowUsesCompactUtilitySize() {
        let controller = PermissionOnboardingWindowController(
            viewModel: PermissionOnboardingViewModel(
                permissionStatusProvider: PermissionStatusProviderStub(
                    accessibilityAuthorized: false,
                    inputMonitoringAuthorized: false
                ),
                permissionPrompter: PermissionPrompterStub()
            )
        )

        let contentSize = try? XCTUnwrap(contentSize(for: controller.window))

        XCTAssertEqual(contentSize?.width, 860)
        XCTAssertEqual(contentSize?.height, 540)
    }

    func testUIPreviewWindowUsesStandalonePreviewViewAsRootView() throws {
        let controller = UIPreviewWindowController()

        let hostingController = try XCTUnwrap(
            controller.window?.contentViewController as? NSHostingController<UIPreviewCatalogView>
        )

        XCTAssertNotNil(hostingController.view)
    }

    func testUIPreviewWindowUsesLargePreviewSize() {
        let controller = UIPreviewWindowController()

        let contentSize = try? XCTUnwrap(contentSize(for: controller.window))

        XCTAssertEqual(contentSize?.width, 1360)
        XCTAssertEqual(contentSize?.height, 900)
    }

    func testSettingsWindowUsesHiddenTitleWithUnifiedToolbarChrome() {
        let controller = SettingsWindowController(viewModel: AppSettingsViewModel())

        XCTAssertEqual(controller.window?.titleVisibility, .hidden)
        XCTAssertEqual(controller.window?.toolbarStyle, .unifiedCompact)
        XCTAssertEqual(controller.window?.titlebarSeparatorStyle, NSTitlebarSeparatorStyle.none)
    }

    func testPermissionOnboardingWindowUsesHiddenTitleWithUnifiedToolbarChrome() {
        let controller = PermissionOnboardingWindowController(
            viewModel: PermissionOnboardingViewModel(
                permissionStatusProvider: PermissionStatusProviderStub(
                    accessibilityAuthorized: false,
                    inputMonitoringAuthorized: false
                ),
                permissionPrompter: PermissionPrompterStub()
            )
        )

        XCTAssertEqual(controller.window?.titleVisibility, .hidden)
        XCTAssertEqual(controller.window?.toolbarStyle, .unifiedCompact)
        XCTAssertEqual(controller.window?.titlebarSeparatorStyle, NSTitlebarSeparatorStyle.none)
    }
}

private extension SettingsWindowControllerTests {
    func contentSize(for window: NSWindow?) throws -> NSSize {
        let window = try XCTUnwrap(window)
        return window.contentRect(forFrameRect: window.frame).size
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

private struct PermissionPrompterStub: PermissionPrompting {
    func requestAccessibilityPermission() {}
    func requestInputMonitoringPermission() {}
}
