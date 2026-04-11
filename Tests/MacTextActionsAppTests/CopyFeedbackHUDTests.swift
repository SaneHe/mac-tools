import XCTest
@testable import MacTextActionsApp

@MainActor
final class CopyFeedbackHUDTests: XCTestCase {
    func testCopyFeedbackStateStartsHidden() {
        let state = CopyFeedbackState()

        XCTAssertFalse(state.isVisible)
        XCTAssertEqual(state.replayToken, 0)
    }

    func testCopyFeedbackStateBecomesVisibleAfterTrigger() {
        let state = CopyFeedbackState()

        state.show()

        XCTAssertTrue(state.isVisible)
        XCTAssertEqual(state.replayToken, 1)
    }

    func testCopyFeedbackStateIncrementsReplayTokenForRepeatedTrigger() {
        let state = CopyFeedbackState()

        state.show()
        state.show()

        XCTAssertTrue(state.isVisible)
        XCTAssertEqual(state.replayToken, 2)
    }

    func testCopyFeedbackStateHidesAfterExplicitDismiss() {
        let state = CopyFeedbackState()
        state.show()

        state.hide()

        XCTAssertFalse(state.isVisible)
        XCTAssertEqual(state.replayToken, 1)
    }
}
