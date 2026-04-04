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
}
