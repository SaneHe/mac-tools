import XCTest
@testable import MacTextActionsApp

final class ToolContentLayoutTests: XCTestCase {
    func testLiquidGlassPopoverLayoutHidesHeaderByDefault() {
        XCTAssertFalse(LiquidGlassPopoverLayout.default.showsHeader)
    }

    func testResultPanelLayoutStateKeepsActionSlotsHiddenWithoutRemovingSpace() {
        let state = ResultPanelLayoutState.make(hasOutput: false)

        XCTAssertFalse(state.showsActions)
        XCTAssertEqual(state.copyButtonOpacity, 0)
        XCTAssertEqual(state.actionBarOpacity, 0)
    }

    func testResultPanelLayoutStateShowsReservedActionSlotsWhenOutputExists() {
        let state = ResultPanelLayoutState.make(hasOutput: true)

        XCTAssertTrue(state.showsActions)
        XCTAssertEqual(state.copyButtonOpacity, 1)
        XCTAssertEqual(state.actionBarOpacity, 1)
    }

    func testSplitWorkspaceSurfaceStyleUsesCardLikeContentPanel() {
        let style = SplitWorkspaceSurfaceStyle.codexLike

        XCTAssertEqual(style.outerPadding, 18)
        XCTAssertEqual(style.contentCornerRadius, 24)
        XCTAssertEqual(style.contentBorderOpacity, 0.82, accuracy: 0.001)
        XCTAssertEqual(style.shadowOpacity, 0.08, accuracy: 0.001)
        XCTAssertEqual(style.shadowRadius, 18)
    }
}
