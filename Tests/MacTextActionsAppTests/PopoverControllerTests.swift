import XCTest
import AppKit
@testable import MacTextActionsApp

@MainActor
final class PopoverControllerTests: XCTestCase {
    func testAnchorWindowCollectionBehaviorUsesOnlySafeFlags() {
        let behavior = PopoverAnchorWindowConfiguration.makeCollectionBehavior()

        XCTAssertEqual(behavior, [.moveToActiveSpace, .transient])
        XCTAssertFalse(behavior.contains(.canJoinAllSpaces))
    }

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

    func testResolveFrameClampsAnchorIntoCurrentVisibleScreen() {
        let frame = PopoverAnchorWindowFrameResolver.resolveFrame(
            mouseLocation: CGPoint(x: 3970, y: 10),
            screenFrames: [
                CGRect(x: 0, y: 0, width: 1728, height: 1117),
                CGRect(x: 1728, y: 0, width: 2560, height: 1440)
            ],
            visibleScreenFrames: [
                CGRect(x: 0, y: 25, width: 1728, height: 1052),
                CGRect(x: 1728, y: 50, width: 2560, height: 1350)
            ]
        )

        XCTAssertEqual(frame.width, PopoverAnchorWindowMetrics.anchorSize)
        XCTAssertEqual(frame.height, PopoverAnchorWindowMetrics.anchorSize)
        XCTAssertGreaterThanOrEqual(frame.minX, 1728)
        XCTAssertGreaterThanOrEqual(frame.minY, 50)
        XCTAssertLessThanOrEqual(frame.maxX, 1728 + 2560)
        XCTAssertLessThanOrEqual(frame.maxY, 50 + 1350)
    }
}
