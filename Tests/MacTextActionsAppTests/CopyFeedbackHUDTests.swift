import XCTest
@testable import MacTextActionsApp

@MainActor
final class CopyFeedbackHUDTests: XCTestCase {
    func testCopyFeedbackStateAutoHidesAfterConfiguredDelay() {
        let expectation = expectation(description: "反馈会自动隐藏")
        let state = CopyFeedbackState(autoHideDelay: 0.05)

        state.show()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            XCTAssertFalse(state.isVisible)
            XCTAssertEqual(state.replayToken, 1)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testCopyFeedbackStateRepeatedTriggerKeepsLatestVisibilityWindow() {
        let expectation = expectation(description: "重复触发会重置自动隐藏计时")
        let state = CopyFeedbackState(autoHideDelay: 0.08)

        state.show()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            state.show()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            XCTAssertTrue(state.isVisible)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            XCTAssertFalse(state.isVisible)
            XCTAssertEqual(state.replayToken, 2)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

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
