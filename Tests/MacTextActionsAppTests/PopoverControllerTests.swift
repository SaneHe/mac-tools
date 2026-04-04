import XCTest
import AppKit
@testable import MacTextActionsApp

@MainActor
final class PopoverControllerTests: XCTestCase {
    func testResolveAnchorViewFallsBackToStatusItemButtonWhenWindowViewMissing() {
        let statusButton = NSStatusBarButton(frame: NSRect(x: 0, y: 0, width: 24, height: 24))

        let anchorView = PopoverAnchorResolver.resolveAnchorView(
            windowContentView: nil,
            statusItemButton: statusButton
        )

        XCTAssertTrue(anchorView === statusButton)
    }

    func testResolveAnchorViewPrefersWindowContentViewWhenAvailable() {
        let windowView = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 60))
        let statusButton = NSStatusBarButton(frame: NSRect(x: 0, y: 0, width: 24, height: 24))

        let anchorView = PopoverAnchorResolver.resolveAnchorView(
            windowContentView: windowView,
            statusItemButton: statusButton
        )

        XCTAssertTrue(anchorView === windowView)
    }

    func testResolveAnchorViewReturnsNilWhenNoAnchorExists() {
        let anchorView = PopoverAnchorResolver.resolveAnchorView(
            windowContentView: nil,
            statusItemButton: nil
        )

        XCTAssertNil(anchorView)
    }
}
