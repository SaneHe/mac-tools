import XCTest
import AppKit
import MacTextActionsCore
@testable import MacTextActionsApp

final class ToolContentLayoutTests: XCTestCase {
    func testSelectionContentSourceUsesExpectedChineseCopy() {
        XCTAssertEqual(SelectionContentSource.selection.displayLabel, "来源：当前选中文本")
        XCTAssertEqual(SelectionContentSource.clipboardFallback.displayLabel, "来源：剪贴板回退")
    }

    func testSourceNoticeStateHidesFallbackLabelWhenMessageAlreadyExplainsClipboardUsage() {
        let state = LiquidGlassPopoverSourceNoticeState.make(
            contentSource: .clipboardFallback,
            sourceMessage: "已改用剪贴板内容"
        )

        XCTAssertNil(state.sourceLabel)
        XCTAssertEqual(state.sourceMessage, "已改用剪贴板内容")
    }

    func testLiquidGlassPopoverResultLayoutUsesStableMinimumHeights() {
        let textResult = TransformResult(
            primaryOutput: "2025-04-04 12:30:45",
            secondaryActions: [.copyResult],
            displayMode: .text
        )

        XCTAssertEqual(
            LiquidGlassPopoverResultLayout.minHeight(
                result: textResult,
                isEditing: false,
                popoverWidth: LiquidGlassPopoverWidthPolicy.defaultWidth
            ),
            96
        )
        XCTAssertEqual(
            LiquidGlassPopoverResultLayout.minHeight(
                result: textResult,
                isEditing: true,
                popoverWidth: LiquidGlassPopoverWidthPolicy.defaultWidth
            ),
            132
        )
    }

    func testLiquidGlassPopoverResultLayoutExpandsForMultilineCodeOutput() {
        let result = TransformResult(
            primaryOutput: """
            {
              "code": 0,
              "data": {
                "list": [
                  {
                    "id": 1
                  },
                  {
                    "id": 2
                  }
                ]
              }
            }
            """,
            secondaryActions: [.copyResult, .replaceSelection, .compressJSON],
            displayMode: .code
        )

        XCTAssertGreaterThan(
            LiquidGlassPopoverResultLayout.minHeight(
                result: result,
                isEditing: false,
                popoverWidth: LiquidGlassPopoverWidthPolicy.defaultWidth
            ),
            96
        )
    }

    func testLiquidGlassPopoverDisplayStateUsesLiveEditResultWhenEditing() {
        let previewResult = TransformResult(
            primaryOutput: "2025-04-04 12:30:45",
            secondaryActions: [.copyResult],
            displayMode: .text
        )
        let liveEditResult = TransformResult(
            primaryOutput: "1775530800",
            secondaryActions: [.copyResult],
            displayMode: .text
        )

        let state = LiquidGlassPopoverDisplayState.make(
            result: previewResult,
            liveEditResult: liveEditResult,
            isEditing: true
        )

        XCTAssertEqual(state.primaryOutput, "1775530800")
        XCTAssertNil(state.errorMessage)
    }

    func testLiquidGlassPopoverDisplayStateUsesPreviewResultWhenNotEditing() {
        let previewResult = TransformResult(
            primaryOutput: "2025-04-04 12:30:45",
            secondaryActions: [.copyResult],
            displayMode: .text
        )
        let liveEditResult = TransformResult(
            primaryOutput: "1775530800",
            secondaryActions: [.copyResult],
            displayMode: .text
        )

        let state = LiquidGlassPopoverDisplayState.make(
            result: previewResult,
            liveEditResult: liveEditResult,
            isEditing: false
        )

        XCTAssertEqual(state.primaryOutput, "2025-04-04 12:30:45")
        XCTAssertNil(state.errorMessage)
    }

    func testLiquidGlassPopoverLayoutHidesHeaderByDefault() {
        XCTAssertFalse(LiquidGlassPopoverLayout.default.showsHeader)
    }

    func testLiquidGlassPopoverLayoutKeepsTimestampWidthCompact() {
        let result = TransformResult(
            primaryOutput: "2025-04-04 12:30:45",
            secondaryActions: [.copyResult],
            displayMode: .text
        )

        let layout = LiquidGlassPopoverLayout.make(
            result: result,
            selectedText: "1712205045"
        )

        XCTAssertEqual(layout.popoverWidth, 320)
    }

    func testLiquidGlassPopoverLayoutWidensForLongURLContent() {
        let longURL = "https://example.com/path/to/really/long/resource-name?token=abcdef1234567890&scene=popover-width-check&redirect=https%3A%2F%2Fopenai.com"
        let result = TransformResult(
            primaryOutput: longURL,
            secondaryActions: [.copyResult],
            displayMode: .text
        )

        let layout = LiquidGlassPopoverLayout.make(
            result: result,
            selectedText: longURL
        )

        XCTAssertEqual(layout.popoverWidth, 680)
    }

    func testLiquidGlassPopoverLayoutClampsJSONWidthToMaximumRange() {
        let jsonOutput = """
        {
          "user": {
            "id": 123,
            "profile": {
              "displayName": "Mac Text Actions",
              "callbackURL": "https://example.com/api/v1/callback/with/a/very/long/path/value/that/should/stretch/the/popover/layout"
            }
          }
        }
        """
        let result = TransformResult(
            primaryOutput: jsonOutput,
            secondaryActions: [.copyResult, .replaceSelection, .compressJSON],
            displayMode: .code
        )

        let layout = LiquidGlassPopoverLayout.make(
            result: result,
            selectedText: "{\"user\":{\"id\":123}}"
        )

        XCTAssertEqual(layout.popoverWidth, 680)
    }

    func testLiquidGlassPopoverLayoutUsesLargestWidthForVeryLongURLContent() {
        let veryLongURL = "/click?source=toutiao&project=reader_free&adid=1861158724900259&imei=__IMEI__&idfa=__IDFA__&caid=__CAID__&is_mcaid=0&mac=__MAC__&ip=240e:45d:8c30:2ace:ec75:49ff:fe2b:ad83&ip4=__IPV4__&ip6=__IPV6__&ua=com.ss.android.ugc.live%2F380301%20%28linux%3B%20u%3B%20android%2015%3B%20zh_cn_%23hans%3B%20ali-an00%3B%20build%2Fhonorali-an00%3B%20cronet%2Fttnetversion%3A8d40f833%202026-03-03%20quicversion%3A21ac1950%202025-11-18%29&os=0&timestamp=1775296083389&callback=B.taU4oDphvaTCcoR224iEuWW6ifNPvoTAfQ2ZiM8xXN3R2stsZX8rDFltWCbrl3xfT8277CRzTDerK7UWGZvpsECkql51AOZlfgFwR6gsnfHGwQqXBLfqRqUMVro9hjI1ITpQame91zX9JmSoIbLrG1J&csite=30001&ctype=15&convert_id=__CONVERT_ID__&oaid=95069e7d-4d29-41ee-bf7d-d422075d560e&cid=20260404173650435FBFFDB1F36DA51B17&account_id=1855449138767879&creative_id=1861158759358515"
        let result = TransformResult(
            primaryOutput: veryLongURL,
            secondaryActions: [.copyResult],
            displayMode: .text
        )

        let layout = LiquidGlassPopoverLayout.make(
            result: result,
            selectedText: veryLongURL
        )

        XCTAssertEqual(layout.popoverWidth, 760)
    }

    func testLiquidGlassPopoverResultLayoutExpandsForWrappedLongTextOutput() {
        let longURL = "/click?m=tapi&project=reader_free&adid=1861777926894729&imei=__IMEI__&idfa=__IDFA__&caid=__CAID__&is_mcaid=0&mac=__MAC__&ip=112.3.50.45&ip4=__IPV4__&ip6=__IPV6__&ua=com.ss.android.ugc.aweme.lite/380301 (linux; u; android 16; zh_cn; v2339a; build/bp2a.250605.031.a3; cronet/ttnetversion:8d40f833 2026-03-03 quicversion:21ac1950)"
        let result = TransformResult(
            primaryOutput: longURL,
            secondaryActions: [.copyResult, .replaceSelection],
            displayMode: .text
        )

        let minHeight = LiquidGlassPopoverResultLayout.minHeight(
            result: result,
            isEditing: false,
            popoverWidth: LiquidGlassPopoverWidthPolicy.maximumWidth
        )

        XCTAssertGreaterThanOrEqual(minHeight, 220)
    }

    func testPopoverAnchorWindowFrameResolverKeepsAnchorOnScreenContainingMouseLocation() {
        let primaryScreen = NSRect(x: 0, y: 0, width: 1440, height: 900)
        let secondaryScreen = NSRect(x: 1440, y: 0, width: 1728, height: 1117)
        let mouseLocation = CGPoint(x: 2100, y: 540)

        let frame = PopoverAnchorWindowFrameResolver.resolveFrame(
            mouseLocation: mouseLocation,
            screenFrames: [primaryScreen, secondaryScreen],
            visibleScreenFrames: [primaryScreen, secondaryScreen]
        )

        XCTAssertTrue(secondaryScreen.contains(frame.origin))
        XCTAssertEqual(frame.size.width, PopoverAnchorWindowMetrics.anchorSize)
        XCTAssertEqual(frame.size.height, PopoverAnchorWindowMetrics.anchorSize)
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
