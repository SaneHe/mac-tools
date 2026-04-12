import XCTest
import AppKit
import MacTextActionsCore
import SwiftUI
@testable import MacTextActionsApp

final class ToolContentLayoutTests: XCTestCase {
    func testSelectionContentSourceUsesExpectedChineseCopy() {
        XCTAssertEqual(SelectionContentSource.selection.displayLabel, "来源：当前选中文本")
        XCTAssertEqual(SelectionContentSource.clipboardFallback.displayLabel, "来源：剪贴板回退")
    }

    func testSourceNoticeStateHidesFallbackLabelWhenMessageAlreadyExplainsClipboardUsage() {
        let state = LiquidGlassPopoverSourceNoticeState.make(
            contentSource: .clipboardFallback,
            sourceMessage: "已改用剪贴板内容，不是当前实时选区"
        )

        XCTAssertNil(state.sourceLabel)
        XCTAssertEqual(state.sourceMessage, "已改用剪贴板内容，不是当前实时选区")
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

    func testLiquidGlassPopoverLayoutShowsHeaderByDefault() {
        XCTAssertTrue(LiquidGlassPopoverLayout.default.showsHeader)
    }

    func testLiquidGlassPopoverHeaderPresentationOmitsExplicitCloseButton() {
        XCTAssertFalse(LiquidGlassPopoverHeaderPresentation.standard.showsCloseButton)
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

    func testOptionActionVisibilityStateTracksWhetherResultHasOptionAction() {
        let withoutOption = TransformResult(
            primaryOutput: "2025-04-04 12:30:45",
            secondaryActions: [.copyResult],
            displayMode: .text
        )
        let withOption = TransformResult(
            primaryOutput: "1709901296",
            secondaryActions: [.copyResult, .replaceSelection],
            optionAction: OptionAction(
                buttonTitle: "转毫秒",
                nextContext: TransformContext(timestampPrecision: .milliseconds)
            ),
            displayMode: .text
        )

        XCTAssertFalse(ResultOptionActionState.make(result: withoutOption).isVisible)
        XCTAssertEqual(ResultOptionActionState.make(result: withOption).buttonTitle, "转毫秒")
        XCTAssertTrue(ResultOptionActionState.make(result: withOption).isVisible)
    }

    @MainActor
    func testPopoverCopyFeedbackStateStartsHidden() {
        let state = PopoverCopyFeedbackState()

        XCTAssertFalse(state.isVisible)
    }

    @MainActor
    func testPopoverCopyFeedbackStateIncrementsReplayTokenWhenTriggeredRepeatedly() {
        let state = PopoverCopyFeedbackState()

        state.show()
        state.show()

        XCTAssertTrue(state.isVisible)
        XCTAssertEqual(state.replayToken, 2)
    }

    func testPopoverCopyFeedbackDismissDelayUsesStableDuration() {
        XCTAssertEqual(PopoverCopyFeedbackMetrics.dismissDelay, 0.65, accuracy: 0.001)
    }

    func testSplitWorkspaceSurfaceStyleUsesCardLikeContentPanel() {
        let style = SplitWorkspaceSurfaceStyle.codexLike

        XCTAssertEqual(style.outerPadding, 18)
        XCTAssertEqual(style.contentCornerRadius, 28)
        XCTAssertEqual(style.contentBorderOpacity, 0.72, accuracy: 0.001)
        XCTAssertEqual(style.shadowOpacity, 0.05, accuracy: 0.001)
        XCTAssertEqual(style.shadowRadius, 14)
    }

    func testSettingsChromeUsesLighterSurfacePalette() {
        let window = rgba(from: SettingsChrome.windowBackground)
        let workspace = rgba(from: SettingsChrome.workspaceBackground)
        let sidebar = rgba(from: SettingsChrome.sidebarBackground)
        let cardSurface = rgba(from: SettingsChrome.cardSurface)
        let shadow = rgba(from: SettingsChrome.shadowColor)

        XCTAssertGreaterThanOrEqual(window.red, 0.96)
        XCTAssertGreaterThanOrEqual(workspace.red, 0.98)
        XCTAssertGreaterThanOrEqual(sidebar.red, 0.90)
        XCTAssertGreaterThanOrEqual(cardSurface.alpha, 0.88)
        XCTAssertLessThanOrEqual(shadow.alpha, 0.02)
    }

    func testSurfaceButtonPaletteUsesBorderlessRoundedLightAppearance() {
        let primary = SurfaceButtonPalette.make(role: .primary, isEnabled: true)
        let secondary = SurfaceButtonPalette.make(role: .secondary, isEnabled: true)

        XCTAssertFalse(primary.showsBorder)
        XCTAssertFalse(secondary.showsBorder)
        XCTAssertEqual(primary.cornerRadius, 14)
        XCTAssertEqual(secondary.cornerRadius, 14)
        XCTAssertEqual(primary.minimumHeight, 30)
        XCTAssertEqual(secondary.minimumHeight, 30)

        let primaryBackground = rgba(from: primary.backgroundColor)
        let secondaryBackground = rgba(from: secondary.backgroundColor)

        XCTAssertGreaterThanOrEqual(primaryBackground.red, 0.84)
        XCTAssertGreaterThanOrEqual(primaryBackground.green, 0.90)
        XCTAssertGreaterThanOrEqual(secondaryBackground.red, 0.94)
        XCTAssertGreaterThanOrEqual(secondaryBackground.green, 0.95)
    }

    func testCompactSurfaceButtonPaletteUsesSmallerActionBarMetrics() {
        let compactPrimary = SurfaceButtonPalette.make(
            role: .primary,
            size: .compact,
            isEnabled: true
        )
        let regularPrimary = SurfaceButtonPalette.make(
            role: .primary,
            size: .regular,
            isEnabled: true
        )

        XCTAssertLessThan(compactPrimary.minimumHeight, regularPrimary.minimumHeight)
        XCTAssertLessThan(compactPrimary.horizontalPadding, regularPrimary.horizontalPadding)
        XCTAssertEqual(compactPrimary.cornerRadius, 12)
    }

    func testSurfaceIconBadgePaletteUsesStableNeutralDesktopAppearance() {
        let palette = SurfaceIconBadgePalette.neutral

        XCTAssertEqual(palette.sideLength, 28)
        XCTAssertEqual(palette.cornerRadius, SettingsChrome.compactCornerRadius)
        XCTAssertEqual(palette.borderWidth, SettingsChrome.borderWidth)

        let background = rgba(from: palette.backgroundColor)
        let border = rgba(from: palette.borderColor)

        XCTAssertGreaterThan(background.alpha, 0.68)
        XCTAssertLessThan(background.alpha, 0.72)
        XCTAssertGreaterThan(border.alpha, 0.20)
        XCTAssertLessThan(border.alpha, 0.30)
    }

    func testSurfaceIconBadgePaletteUsesTintedAccentAppearanceForHighlights() {
        let palette = SurfaceIconBadgePalette.tinted(
            tintColor: SettingsChrome.accent,
            sideLength: 30
        )

        XCTAssertEqual(palette.sideLength, 30)
        XCTAssertEqual(palette.cornerRadius, 12)
        XCTAssertEqual(palette.borderWidth, SettingsChrome.borderWidth)

        let background = rgba(from: palette.backgroundColor)
        let border = rgba(from: palette.borderColor)

        XCTAssertGreaterThan(background.alpha, 0.09)
        XCTAssertLessThan(background.alpha, 0.13)
        XCTAssertGreaterThan(border.alpha, 0.13)
        XCTAssertLessThan(border.alpha, 0.19)
    }

    private func rgba(from color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .clear
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }

}
