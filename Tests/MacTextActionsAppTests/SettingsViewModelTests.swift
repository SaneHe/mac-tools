import XCTest
@testable import MacTextActionsApp

@MainActor
final class ToolWorkspaceViewModelTests: XCTestCase {
    func testChangingSelectedToolClearsInputAndOutput() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.contentViewModel.inputText = "1711111111"
        viewModel.contentViewModel.outputText = "2024-03-22 10:38:31"

        viewModel.selectedTool = .md5

        XCTAssertEqual(viewModel.contentViewModel.inputText, "")
        XCTAssertEqual(viewModel.contentViewModel.outputText, "")
    }

    func testSelectingToolByShortcutClearsInputAndOutput() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.contentViewModel.inputText = "{\"name\":\"mac\"}"
        viewModel.contentViewModel.outputText = "formatted"

        viewModel.selectTool(usingShortcut: 4)

        XCTAssertEqual(viewModel.selectedTool, .url)
        XCTAssertEqual(viewModel.contentViewModel.inputText, "")
        XCTAssertEqual(viewModel.contentViewModel.outputText, "")
    }

    func testPerformPrimaryActionUsesSelectedTool() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.selectedTool = .md5
        viewModel.contentViewModel.inputText = "hello"

        viewModel.performPrimaryAction()

        XCTAssertEqual(
            viewModel.contentViewModel.outputText,
            "5d41402abc4b2a76b9719d911017c592"
        )
    }

    func testMD5ToolOptionActionTogglesToUppercaseOutput() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.selectedTool = .md5
        viewModel.contentViewModel.inputText = "hello"

        viewModel.performPrimaryAction()

        XCTAssertEqual(viewModel.contentViewModel.outputText, "5d41402abc4b2a76b9719d911017c592")
        XCTAssertEqual(viewModel.contentViewModel.optionActionTitle, "转大写")

        viewModel.contentViewModel.toggleOptionAction(for: .md5)

        XCTAssertEqual(viewModel.contentViewModel.outputText, "5D41402ABC4B2A76B9719D911017C592")
        XCTAssertEqual(viewModel.contentViewModel.optionActionTitle, "转小写")
    }

    func testTimestampToolOptionActionTogglesToMillisecondOutputForDateInput() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.selectedTool = .timestamp
        viewModel.contentViewModel.inputText = "2024-03-08T12:34:56Z"

        viewModel.performPrimaryAction()

        XCTAssertEqual(viewModel.contentViewModel.outputText, "1709901296")
        XCTAssertEqual(viewModel.contentViewModel.optionActionTitle, "转毫秒")

        viewModel.contentViewModel.toggleOptionAction(for: .timestamp)

        XCTAssertEqual(viewModel.contentViewModel.outputText, "1709901296000")
        XCTAssertEqual(viewModel.contentViewModel.optionActionTitle, "转秒级")
    }

    func testClearCurrentToolContentClearsInputAndOutput() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.contentViewModel.inputText = "1711111111"
        viewModel.contentViewModel.outputText = "2024-03-22 10:38:31"

        viewModel.clearCurrentToolContent()

        XCTAssertEqual(viewModel.contentViewModel.inputText, "")
        XCTAssertEqual(viewModel.contentViewModel.outputText, "")
    }

    func testCopyCurrentOutputWritesOutputText() {
        let outputCopyWriter = OutputCopyWriterSpy()
        let toolContentViewModel = ToolContentViewModel(outputCopyWriter: outputCopyWriter)
        let viewModel = ToolWorkspaceViewModel(contentViewModel: toolContentViewModel)
        viewModel.contentViewModel.outputText = "copied-value"

        let didCopy = viewModel.copyCurrentOutput()

        XCTAssertTrue(didCopy)
        XCTAssertEqual(outputCopyWriter.copiedTexts, ["copied-value"])
    }

    func testCopyCurrentOutputShowsCopyFeedbackWhenCopySucceeds() {
        let outputCopyWriter = OutputCopyWriterSpy()
        let toolContentViewModel = ToolContentViewModel(outputCopyWriter: outputCopyWriter)
        let viewModel = ToolWorkspaceViewModel(contentViewModel: toolContentViewModel)
        viewModel.contentViewModel.outputText = "copied-value"

        let didCopy = viewModel.copyCurrentOutput()

        XCTAssertTrue(didCopy)
        XCTAssertTrue(viewModel.copyFeedbackState.isVisible)
        XCTAssertEqual(viewModel.copyFeedbackState.replayToken, 1)
    }

    func testCopyCurrentOutputDoesNotShowCopyFeedbackWhenOutputMissing() {
        let outputCopyWriter = OutputCopyWriterSpy()
        let toolContentViewModel = ToolContentViewModel(outputCopyWriter: outputCopyWriter)
        let viewModel = ToolWorkspaceViewModel(contentViewModel: toolContentViewModel)

        let didCopy = viewModel.copyCurrentOutput()

        XCTAssertFalse(didCopy)
        XCTAssertFalse(viewModel.copyFeedbackState.isVisible)
        XCTAssertTrue(outputCopyWriter.copiedTexts.isEmpty)
    }
}

@MainActor
final class AppSettingsViewModelTests: XCTestCase {
    func testShortcutRecorderStatusMessageUsesBoundShortcutAfterSuccess() {
        let feedback = ShortcutRecorderFeedback.success(
            ShortcutConfiguration(
                keyCode: ShortcutConfiguration.KeyCode.space,
                modifiers: [.option]
            )
        )

        XCTAssertEqual(feedback.message, "快捷键已绑定为 ⌥+Space")
    }

    func testShortcutDisplayStringUsesModifierSymbolsAndReadableKeyName() {
        let configuration = ShortcutConfiguration(
            keyCode: ShortcutConfiguration.KeyCode.space,
            modifiers: [.option, .shift]
        )

        XCTAssertEqual(configuration.displayString, "⌥+⇧+Space")
    }

    func testShortcutDisplayStringUsesReadableLetterKeyName() {
        let configuration = ShortcutConfiguration(
            keyCode: 0,
            modifiers: [.command]
        )

        XCTAssertEqual(configuration.displayString, "⌘+A")
    }

    func testShortcutSummaryUsesMenuCommandShortcuts() {
        let permissionStatusProvider = PermissionStatusProviderStub(
            accessibilityAuthorized: true,
            inputMonitoringAuthorized: true
        )
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: permissionStatusProvider
        )

        XCTAssertEqual(viewModel.globalShortcutDisplayTitle, "全局触发")
        XCTAssertEqual(viewModel.globalShortcutDisplayValue, "⌥+Space")
        XCTAssertEqual(
            viewModel.toolSwitchShortcutDisplayValue,
            "⌘1 自动识别 / ⌘2 MD5 / ⌘3 JSON Compress（菜单展开时切换模式）"
        )
    }

    func testPermissionSummaryUsesGrantedCopyWhenAllPermissionsAreReady() {
        let permissionStatusProvider = PermissionStatusProviderStub(
            accessibilityAuthorized: true,
            inputMonitoringAuthorized: true
        )
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: permissionStatusProvider
        )

        XCTAssertEqual(viewModel.accessibilityPermissionText, "已授权")
        XCTAssertEqual(viewModel.inputMonitoringPermissionText, "已授权")
    }

    func testPermissionSummaryUsesGuidanceCopyWhenPermissionMissing() {
        let permissionStatusProvider = PermissionStatusProviderStub(
            accessibilityAuthorized: false,
            inputMonitoringAuthorized: false
        )
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: permissionStatusProvider
        )

        XCTAssertEqual(viewModel.accessibilityPermissionText, "需要在系统设置中开启")
        XCTAssertEqual(viewModel.inputMonitoringPermissionText, "需要在系统设置中开启")
    }

    func testGlobalShortcutHintWarnsWhenSystemMayRejectOptionOnlyShortcut() {
        let configuration = ShortcutConfiguration(
            keyCode: ShortcutConfiguration.KeyCode.space,
            modifiers: [.option]
        )
        let warning = HotKeySystemSupport.warningMessage(
            for: configuration,
            osVersion: OperatingSystemVersion(majorVersion: 15, minorVersion: 2, patchVersion: 0)
        )

        XCTAssertEqual(
            warning,
            "当前系统对仅含 ⌥ / ⇧ 的全局快捷键支持受限，若未生效请改为包含 ⌘ 或 ⌃ 的组合。"
        )
    }
}

private final class OutputCopyWriterSpy: OutputCopyWriting {
    private(set) var copiedTexts: [String] = []

    func write(_ text: String) {
        copiedTexts.append(text)
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
